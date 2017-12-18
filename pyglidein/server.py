#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

import subprocess
import threading
import logging
from functools import partial
from optparse import OptionParser
from collections import Counter
import distutils.version
from datetime import datetime
import re

from pyglidein.util import json_encode, json_decode
from pyglidein.config import Config
from pyglidein.metrics_sender_client import MetricsSenderClient
from pyglidein.client_metrics import ClientMetricsBundle
import tornado.escape
tornado.escape.json_encode = json_encode
tornado.escape.json_decode = json_decode

from tornado.ioloop import IOLoop
from tornado.httpserver import HTTPServer
import tornado.web
import tornado.gen

logger = logging.getLogger('server')

job_status = {
    1:'Idle',
    2:'Run',
    3:'Del',
    4:'OK',
    5:'Held',
    6:'Err',
}
def get_job_status(st):
    return job_status[st] if st in job_status else 'Unk'

job_universe = {
    1:'standard',
    4:'PVM',
    5:'vanilla',
    6:'PVMd',
    7:'scheduler',
    8:'MPI',
    9:'grid',
    10:'java',
    11:'parallel',
    12:'local',
}

client_metrics = {
    'glideins_launched': 'glideins.launched',
    'glideins_running': 'glideins.running',
    'glideins_idle': 'glideins.idle',
    'avg_idle_time': 'glideins.avg_idle_time',
    'min_idle_time': 'glideins.min_idle_time',
    'max_idle_time': 'glideins.max_idle_time'
}

class MyHandler(tornado.web.RequestHandler):
    """Default Handler"""
    def initialize(self, cfg):
        """
        Get some params from the website module

        Args:
            cfg: the global config
        """
        self.cfg = cfg
        if self.cfg['metrics_sender_client'] is not None:
            self.metrics_sender_client = self.cfg['metrics_sender_client']
        else:
            self.metrics_sender_client = None

    def get(self):
        """GET is invalid and returns an error"""
        raise tornado.web.HTTPError(400, 'GET is invalid.  Use POST')

    def post(self):
        """POST is invalid and returns an error"""
        raise tornado.web.HTTPError(400, 'POST is invalid.  Use GET')

class JSONRPCHandler(MyHandler):
    """
    JSONRPC 2.0 Handler.

    Call DB methods using RPC over json.
    """

    def post(self):
        """Parses json in the jsonrpc format, returning results in
           jsonrpc format as well.
        """
        # parse JSON
        try:
            request = tornado.escape.json_decode(self.request.body)
        except Exception as e:
            raise tornado.web.HTTPError(400, 'POST request is not valid json')

        # check for all parts of jsonrpc 2.0 spec
        if 'jsonrpc' not in request or request['jsonrpc'] not in ('2.0', 2.0):
            self.json_error({'code':-32600, 'message':'Invalid Request',
                             'data':'jsonrpc is not 2.0'})
        elif 'method' not in request:
            self.json_error({'code':-32600, 'message':'Invalid Request',
                             'data':'method not in request'})
        elif request['method'].startswith('_'):
            self.json_error({'code':-32600, 'message':'Invalid Request',
                             'data':'method name cannot start with underscore'})
        else:
            method = request['method']
            if 'params' in request:
                params = request['params']
            else:
                params = {}
            if 'id' in request:
                request_id = request['id']
            else:
                request_id = None

            # call method
            try:
                if method == 'get_state':
                    ret = self.cfg['state']
                elif method == 'monitoring':
                    client_id = params.pop('uuid')
                    client_id_clean = re.sub(r'\W+', '', client_id)
                    # For Clients > 1.1
                    if 'timestamp' in params and 'metrics' in params:
                        metrics_bundle = ClientMetricsBundle(client_id_clean,
                                                             timestamp=params['timestamp'],
                                                             metrics=params['metrics'])
                    # For Clients < 1.1
                    else:
                        metrics_bundle = ClientMetricsBundle(client_id_clean,
                                                             metrics=params)
                    if self.metrics_sender_client is not None:
                        self.metrics_sender_client.send(metrics_bundle)
                    # Continue sending metrics to old web interface
                    self.cfg['monitoring'][client_id] = metrics_bundle.get_v1_bundle()
                    ret = ''
                else:
                    self.json_error({'code':-32601, 'message':'Method not found'},
                                    request_id=request_id)
                    return
            except:
                self.json_error({'code':-32602, 'message':'Invalid params',
                                 'data':str(ret)}, request_id=request_id)
            else:
                # return response
                self.write({'jsonrpc':'2.0', 'result':ret, 'id':request_id})

    def json_error(self, error, status=400, request_id=None):
        """Create a proper jsonrpc error message"""
        self.set_status(status)
        if isinstance(error, Exception):
            error = str(error)
        logger.info('json_error: %r', error)
        self.write({'jsonrpc':'2.0', 'error':error, 'id':request_id})


class DefaultHandler(MyHandler):
    """Display queue status in html"""
    def get(self):
        self.write("""
<html>
<head>
  <title>Queue Status</title>
  <style>
    .num {
      margin-left: 1em;
    }
    div.clients>div, div.reqs>div {
      margin: .2em;
    }
    div.clients {
      margin-bottom: 1em;
    }
    div.clients>div>span, div.reqs>div>span {
      margin-right: .5em;
      width: 5em;
      display: inline-block;
      vertical-align: top;
    }
    div.clients>div>span {
      width: 15em;
      word-wrap: break-word;
    }
  </style>
</head>
<body>
  <h1>Pyglidein Server</h1>
  <h2>List of requirements</h2>
  <div class="reqs">
    <div><span class="num">Num</span><span>CPUs</span><span>Memory</span><span>Disk</span><span>GPUs</span><span>OS</span></div>""")
        for row in self.cfg['state']:
            self.write('<div><span class="num">'+str(row['count'])+'</span><span>'+str(row['cpus'])+'</span><span>'+str(row['memory'])+'</span><span>'+str(row['disk'])+'</span><span>'+str(row['gpus'])+'</span><span>'+str(row['os'])+'</span></div>')
        self.write("""
  </div>
  <h2>Clients</h2>
  <div class="clients">
    <div><span>UUID</span><span>Last update</span><span>Stats</span></div>""")
        for uuid in self.cfg['monitoring']:
            try:
                info = self.cfg['monitoring'][uuid]
                timestamp = datetime.fromtimestamp(info['timestamp']).strftime('%Y-%m-%d %H:%M:%S')
                stats = '<br>'.join(str(k)+': '+str(info[k]) for k in info if k != 'timestamp')
                self.write('<div><span class="uuid">'+str(uuid)+'</span><span class="date">'+timestamp+'</span><span class="stats">'+stats+'</span></div>')
            except Exception:
                logging.info('error in monitoring display: %r %r',uuid,self.cfg['monitoring'][uuid],exc_info=True)
                continue
        self.write("""
  </div>
</body>
</html>""")


class server:
    def __init__(self, cfg):
        self.cfg = cfg
        handler_args = {'cfg':self.cfg}
        self.application = tornado.web.Application([
            (r"/jsonrpc", JSONRPCHandler, handler_args),
            (r"/.*", DefaultHandler, handler_args),
        ])
    def start(self):
        self.http_server = HTTPServer(self.application, xheaders=True)
        self.http_server.listen(self.cfg["options"].port)
        IOLoop.instance().start()
    def stop(self):
        self.http_server.stop()
        IOLoop.instance().stop()

def get_condor_version():
     p = subprocess.Popen("condor_version", shell=True, stdout=subprocess.PIPE)
     out = p.communicate()[0]
     return out.split(" ")[1]

def condor_q(cfg):
    """Get the status of the HTCondor queue"""
    logger.info('condor_q')
    cmd = ['condor_q', '-global', '-autoformat:,', 'RequestCPUs', 'RequestMemory',
           'RequestDisk', 'RequestGPUs', '-format', '"%s"', 'Requirements',
           '-constraint', '"JobStatus =?= 1"']
    if cfg['options'].constraint:
        cmd += ['-constraint', cfg['options'].constraint]
    if cfg['options'].user:
        cmd += [cfg['options'].user]
    if (distutils.version.LooseVersion(get_condor_version()) >=
         distutils.version.LooseVersion("8.5.2") and
         not cfg['options'].user):
        cmd += ["-allusers"]

    state = []
    try:
        cmd = ' '.join(cmd)
        print(cmd)
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        output = p.communicate()[0]
        for line in output.splitlines():
            logger.debug(line)
            try:
                cpus, memory, disk, gpus, reqs = line.split(', ',4)
                cpus = 1 if cpus == 'undefined' else int(cpus)
                memory = 2000 if memory == 'undefined' else int(memory)
                disk = 10000 if disk == 'undefined' else int(disk)/1000 # convert to MB
                gpus = 0 if gpus == 'undefined' else int(gpus)
                req_os = None
                if 'OpSysAndVer =?= "SL6"' in reqs:
                    req_os = 'sl6'
                state.append((cpus, memory, disk, gpus, req_os))
            except Exception:
                logger.info('error parsing line', exc_info=True)
                continue
        state = [{'cpus':s[0], 'memory':s[1], 'disk':s[2],
                  'gpus':s[3], 'os':s[4], 'count': count} 
                  for s, count in Counter(state).items()]
    except Exception:
        logger.warn('error in condor_q', exc_info=True)
        state = None
    finally:
        def cb():
            # update state only on the main io loop
            logger.info('state is updated to %r', state)
            if state is not None:
                cfg['state'] = state
            cfg['condor_q'] = False
            IOLoop.instance().call_later(cfg['options'].delay,
                                         partial(condor_q_helper, cfg))
        IOLoop.instance().add_callback(cb)

def condor_q_helper(cfg):
    """Helper to launch condor_q in a separate thread"""
    # make sure we're not already running a condor_q
    if not cfg['condor_q']:
        cfg['condor_q'] = True
        t = threading.Thread(target=partial(condor_q, cfg))
        t.daemon = True
        t.start()


def main():
    parser = OptionParser()
    parser.add_option('-p', '--port', type='int', default=11001,
                      help='Port to serve from (default: 11001)')
    parser.add_option('-u', '--user', type='string', default=None,
                      help='Only track a single user')
    parser.add_option('--constraint', type='string', default=None,
                      help='HTCondor constraint expression')
    parser.add_option('--delay', type='int', default=300,
                      help='delay between calls to condor_q (default: 300 seconds)')
    parser.add_option('--debug', action='store_true', default=False,
                      help='Enable debug logging')
    parser.add_option('--config', type='string', default='pyglidein_server.config',
                      help="config file for cluster")
    (options, args) = parser.parse_args()

    config = Config(options.config)

    if options.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    if options.delay < 0 or options.delay > 1000:
        raise Exception('delay out of range')
        
    if config.get('metrics', {}).get('enable_metrics', False):
        metrics_sender_client = MetricsSenderClient(config['metrics'])
    else: metrics_sender_client = None

    cfg = {'options': options, 'config': config, 'condor_q': False, 'state': [], 'monitoring': {},
           'metrics_sender_client': metrics_sender_client}

    # load condor_q
    IOLoop.instance().call_later(5, partial(condor_q_helper, cfg))

    # setup server
    s = server(cfg)
    s.start()

if __name__ == '__main__':
    main()

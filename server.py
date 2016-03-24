#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

import subprocess
import threading
import logging
from functools import partial
from optparse import OptionParser
from collections import Counter
import distutils

from util import json_encode, json_decode
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

class MyHandler(tornado.web.RequestHandler):
    """Default Handler"""
    def initialize(self, cfg):
        """
        Get some params from the website module

        :param cfg: the global config
        """
        self.cfg = cfg

    def get(self):
        """GET is invalid and returns an error"""
        raise tornado.web.HTTPError(400, 'GET is invalid.  Use POST')

    def post(self):
        """POST is invalid and returns an error"""
        raise tornado.web.HTTPError(400, 'POST is invalid.  Use GET')

class JSONRPCHandler(MyHandler):
    """JSONRPC 2.0 Handler.

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
    div.reqs>div {
      margin: .2em;
    }
    div.reqs>div>span {
      margin-right: .5em;
      width: 5em;
      display: inline-block;
    }
  </style>
</head>
<body>
  <h1>List of requirements</h1>
  <div class="reqs">
    <div><span class="num">Num</span><span>CPUs</span><span>Memory</span><span>Disk</span><span>GPUs</span><span>OS</span></div>""")
        c = Counter((x['cpus'],x['memory'],x['disk'],x['gpus'],x['os']) for x in self.cfg['state'])
        for k in c:
            self.write('<div><span class="num">'+str(c[k])+'</span><span>'+'</span><span>'.join(str(x) for x in k)+'</span></div>')
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
    cmd = ['condor_q', '-autoformat:,', 'RequestCPUs', 'RequestMemory',
           'RequestDisk', 'RequestGPUs', '-format', '"%s"', 'Requirements',
           '-constraint', '"JobStatus =?= 1"']
    if cfg['options'].constraint:
        cmd += ['-constraint', cfg['options'].constraint]
    if cfg['options'].user:
        cmd += [cfg['options'].user]
    if ((distutils.version.Looseversion(get_condor_version()) >=
         distutils.version.Looseversion("8.5.2"))
         not cfg['options'].user):
        cmd += ["-allusers"]

    state = []
    try:
        cmd = ' '.join(cmd)
        print(cmd)
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        output = p.communicate()[0]
        for line in output.splitlines():
            logger.info(line)
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
    (options, args) = parser.parse_args()

    if options.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    if options.delay < 0 or options.delay > 1000:
        raise Exception('delay out of range')

    cfg = {'options':options, 'condor_q':False, 'state':[]}

    # load condor_q
    IOLoop.instance().call_later(5, partial(condor_q_helper, cfg))

    # setup server
    s = server(cfg)
    s.start()

if __name__ == '__main__':
    main()

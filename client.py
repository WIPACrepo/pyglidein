#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

import os
import sys
import time
import platform
import subprocess
import logging
import threading
from functools import partial
from optparse import OptionParser
import urllib
import urllib2
import ConfigParser

from util import json_encode,json_decode, config_options_dict

logger = logging.getLogger('client')

class Client(object):
    """Raw JSONRPC client object"""
    id = 0
    idlock = threading.RLock()
    
    def __init__(self,timeout=60.0,address=None,ssl_options=None):
        if address is None:
            raise Exception('need a valid address')
        # save timeout
        self._timeout = timeout
        # save address
        self._address = address
        # save ssl_options
        self._sslopts = ssl_options
    
    @classmethod
    def newid(cls):
        cls.idlock.acquire()
        id = cls.id
        cls.id += 1
        cls.idlock.release()
        return id

    def request(self,methodname,kwargs):
        """Send request to RPC Server"""
        # check method name for bad characters
        if methodname[0] == '_':
            logger.warning('cannot use RPC for private methods')
            raise Exception('Cannot use RPC for private methods')
        
        # translate request to json
        body = json_encode({'jsonrpc':'2.0','method':methodname,'params':kwargs,'id':Client.newid()})
        
        headers = {'Content-type':'application/json'}
        request = urllib2.Request(self._address,data=body,headers=headers)
        
        # make request to server
        try:
            response = urllib2.urlopen(request, timeout=self._timeout)
        except Exception:
            logger.warn('error making jsonrpc request',exc_info=True)
            raise
        
        # translate response from json
        try:
            cb_data = response.read()
            data = json_decode(cb_data)
        except:
            try:
                logger.info('json data: %r',cb_data)
            except:
                pass
            raise
        
        if 'error' in data:
            try:
                raise Exception('Error %r: %r    %r'%data['error'])
            except:
                raise Exception('Error %r'%data['error'])
        if 'result' in data:
            return data['result']
        else:
            return None

def get_state(address):
    c = Client(address=address)
    try:
        return c.request('get_state',{})
    except Exception:
        logger.warn('error getting state',exc_info=True)

def get_ssh_state():
    try:
        filename = os.path.expanduser('~/glidein_state')
        return json_decode(open(filename).read())
    except Exception:
        logger.warn('error getting ssh state',exc_info=True)

def launch_glidein(cmd,params=[]):
    for p in params:
        cmd += ' --'+p+' '+str(params[p])
    print(cmd)
    if subprocess.call(cmd,shell=True):
        raise Exception('failed to launch glidein')

def get_running(cmd):
    p = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE)
    return int(p.communicate()[0].strip())

def main():
    parser = OptionParser()
    parser.add_option('--config', type='string', default='cluster.config',
                      help="config file for cluster")
    (options,args) = parser.parse_args()
    config = ConfigParser.ConfigParser()
    config.read(options.config)
    config_dict = config_options_dict(config)
    
    if config_dict["Cluster"]["scheduler"] == "htcondor":
        from submit import SubmitCondor
        scheduler = SubmitCondor(config_dict)
    elif config_dict["Cluster"]["scheduler"] == "pbs":
        from submit import SubmitPBS
        scheduler = SubmitPBS(config_dict)
    else:
        raise Exception('scheduler not supported')
    
    # if "glidein_cmd" not in config_dict["Glidein"]:
    #     raise Exception('no glidein_cmd')
    if "running_cmd" not in config_dict["Cluster"]:
        raise Exception('no running_cmd')
    
    if config_dict["Mode"]["debug"]:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)
    # sys.exit()
    while True:
        if config_dict["Glidein"]["ssh_state"]:
            state = get_ssh_state()
        else:
            state = get_state(config_dict["Glidein"]["address"])
        if state:
            try:
                glideins_running = get_running(config_dict["Cluster"]["running_cmd"])
            except Exception:
                logger.warn('error getting running job count',exc_info=True)
                continue
            i = 0
            for s in state:
                # Skipping CPU jobs for gpu only clusters
                if config_dict["Cluster"]["gpu_only"] and s["gpus"] == 0:
                    continue
                # skipping GPU jobs for cpu only clusters
                if config_dict["Cluster"]["cpu_only"] and s["gpus"] != 0:
                    continue
                if i >= config_dict["Cluster"]["limit_per_submit"] or i + glideins_running >= config_dict["Cluster"]["max_total_jobs"]:
                    logger.info('reached limit')
                    break
                scheduler.submit(s)
                i += 1
            logger.info('launched %d glideins',i)
        else:
            logger.info('no state, nothing to do')
        
        if int(config_dict["Glidein"]["delay"]) < 1:
            break
        time.sleep(config_dict["Glidein"]["delay"])
        

if __name__ == '__main__':
    main()

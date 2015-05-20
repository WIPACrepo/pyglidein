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

from util import json_encode,json_decode

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
    parser.add_option('--address',type='string',default='http://bosco.icecube.wisc.edu:9070',
                      help='Address to connect to (default: http://bosco.icecube.wisc.edu:9070)')
    parser.add_option('--ssh',action='store_true',default=False,
                      help='Use ssh file for state')
    parser.add_option('--limit',type='int',default=10,
                      help='# of glideins to submit per round (default: 10)')
    parser.add_option('--max-limit',type='int',dest='maxlimit',default=900,
                      help='max # of glideins to submit (default: 900)')
    parser.add_option('--delay',type='int',default=300,
                      help='delay between calls to server (default: 300 seconds)')
    parser.add_option('--glidein_cmd',type='string',default=None,
                      help='glidein command')
    parser.add_option('--running_cmd',type='string',default=None,
                      help='check # running command')
    parser.add_option('--debug',action='store_true',default=False,
                      help='Enable debug logging')
    (options,args) = parser.parse_args()
    
    if not options.glidein_cmd:
        raise Exception('no glidein_cmd')
    if not options.running_cmd:
        raise Exception('no running_cmd')
    
    if options.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)
    
    while True:
        if options.ssh:
            state = get_ssh_state()
        else:
            state = get_state(options.address)
        if state:
            try:
                glideins_running = get_running(options.running_cmd)
            except Exception:
                logger.warn('error getting running job count',exc_info=True)
                continue
            i = 0
            for i,s in enumerate(state):
                if i >= options.limit or i+glideins_running >= options.maxlimit:
                    logger.info('reached limit')
                    break
                launch_glidein(options.glidein_cmd,s)
            logger.info('launched %d glideins',i)
        else:
            logger.info('no state, nothing to do')
        
        if options.delay < 1:
            break
        time.sleep(options.delay)

if __name__ == '__main__':
    main()

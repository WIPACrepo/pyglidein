"""Utilities used by client.py and ssh_helper.py"""
from __future__ import absolute_import, division, print_function

import logging
import threading
import urllib2
import ast

from util import json_encode, json_decode

logger = logging.getLogger('client_util')

class Client(object):
    """Raw JSONRPC client object"""
    cid = 0
    cidlock = threading.RLock()

    def __init__(self, timeout=60.0, address=None, ssl_options=None):
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
        cls.cidlock.acquire()
        cid = cls.cid
        cls.cid += 1
        cls.cidlock.release()
        return cid

    def request(self, methodname, kwargs):
        """Send request to RPC Server"""
        # check method name for bad characters
        if methodname[0] == '_':
            logger.warning('cannot use RPC for private methods')
            raise Exception('Cannot use RPC for private methods')

        # translate request to json
        body = json_encode({'jsonrpc': '2.0', 'method': methodname,
                            'params': kwargs, 'id': Client.newid()})

        headers = {'Content-type':'application/json'}
        request = urllib2.Request(self._address, data=body, headers=headers)

        # make request to server
        try:
            response = urllib2.urlopen(request, timeout=self._timeout)
        except Exception:
            logger.warn('error making jsonrpc request', exc_info=True)
            raise

        # translate response from json
        try:
            cb_data = response.read()
            data = json_decode(cb_data)
        except Exception:
            try:
                logger.info('json data: %r', cb_data)
            except Exception:
                pass
            raise

        if 'error' in data:
            try:
                raise Exception('Error %r: %r    %r'%data['error'])
            except Exception:
                raise Exception('Error %r'%data['error'])
        if 'result' in data:
            return data['result']
        else:
            return None

def get_state(address):
    c = Client(address=address)
    try:
        return c.request('get_state', {})
    except Exception:
        logger.warn('error getting state', exc_info=True)

def config_options_dict(config):
    config_dict = {}
    for section in config.sections():
        config_dict[section] = {}
        for option in config.options(section):
            val = config.get(section, option)
            try:
                val = ast.literal_eval(val)
            except Exception:
                pass
            config_dict[section][option] = val
    return config_dict

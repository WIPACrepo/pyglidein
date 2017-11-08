"""Utilities used by client.py and ssh_helper.py"""
from __future__ import absolute_import, division, print_function

import logging
import threading
import urllib2
import ast
import datetime

from pyglidein.util import json_encode, json_decode

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
    """Getting the server state directly from remote queue"""
    c = Client(address=address)
    try:
        return c.request('get_state', {})
    except Exception:
        logger.warn('error getting state', exc_info=True)

def monitoring(address,info=None):
    """Sending monitoring information back"""
    if info is None:
        info = {}
    c = Client(address=address)
    try:
        return c.request('monitoring', info)
    except Exception:
        logger.warn('error getting state', exc_info=True)

def config_options_dict(config):
    """
    Parsing config file

    Args:
        config: Pythong config parser object

    Returns:
        A dict with the different sections of the config file
        and the literal values of the configuraton objects
    """
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


def get_presigned_put_url(filename, config, secrets):
    """Generate a presigned put URL using the Minio S3 client.

    Args:
        filename: Name of file to use in S3
        config: Pyglidein cluster config dictionary
        secrets: Pyglidein cluster secrets dictionary

    Returns:
        string: Presigned Put URL

    """
    from minio import Minio
    from minio.error import ResponseError

    config_startd_logging = config['StartdLogging']
    secrets_startd_logging = secrets['StartdLogging']

    client = Minio(config_startd_logging['url'],
                   access_key=secrets_startd_logging['access_key'],
                   secret_key=secrets_startd_logging['secret_key'],
                   secure=True
                   )

    try:
        return client.presigned_put_object(config_startd_logging['bucket'],
                                           filename,
                                           datetime.timedelta(days=1))
    except ResponseError as err:
        print(err)


def get_presigned_get_url(filename, config, secrets):
    """Generate a presigned get URL using the Minio S3 client.

    Args:
        filename: Name of file to use in S3
        config: Pyglidein cluster config dictionary
        secrets: Pyglidein cluster secrets dictionary

    Returns:
        string: Presigned Get URL

    """
    from minio import Minio
    from minio.error import ResponseError
    
    config_startd_logging = config['StartdLogging']
    secrets_startd_logging = secrets['StartdLogging']

    client = Minio(config_startd_logging['url'],
                   access_key=secrets_startd_logging['access_key'],
                   secret_key=secrets_startd_logging['secret_key'],
                   secure=True
                   )

    try:
        return client.presigned_get_object(config_startd_logging['bucket'],
                                           filename)
    except ResponseError as err:
        print(err)

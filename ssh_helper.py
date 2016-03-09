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
import tempfile
import shutil

from util import json_encode
from client_util import get_state

logger = logging.getLogger('client')


def ssh_write(host,state):
    d = tempfile.mkdtemp()
    try:
        filename = os.path.join(d,'glidein_state')
        with open(filename,'w') as f:
            f.write(json_encode(state))
        cmd = ['scp',filename,host+':~/glidein_state']
        if subprocess.call(cmd):
            raise Exception('error in ssh copy of state')
    finally:
        shutil.rmtree(d)

def main():
    parser = OptionParser()
    parser.add_option('--address',type='string',default='http://bosco.icecube.wisc.edu:9070',
                      help='Address to connect to (default: http://bosco.icecube.wisc.edu:9070)')
    parser.add_option('--debug',action='store_true',default=False,
                      help='Enable debug logging')
    parser.add_option('--ssh-host',dest='ssh_host',type='string',
                      default='',help='ssh host')
    (options,args) = parser.parse_args()

    if options.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    state = get_state(options.address)
    if state:
        try:
            ssh_write(options.ssh_host,state)
        except Exception:
            logger.warn('error',exc_info=True)
        else:
            logger.info('done')

if __name__ == '__main__':
    main()

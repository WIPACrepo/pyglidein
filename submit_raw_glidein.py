#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

import os
import sys
import time
import platform
import subprocess
import logging
import tempfile


from util import glidein_parser

logger = logging.getLogger(__name__)

def main():
    logging.basicConfig(level=logging.INFO)
    (options,args) = glidein_parser()
    
    # make tmp dir
    curdir = os.getcwd()
    d = tempfile.mkdtemp(dir=curdir)
    
    os.chdir(d)
    
    try:
        os.symlink('../glidein.tar.gz','glidein.tar.gz')
        os.symlink('../glidein_start.sh','glidein_start.sh')
        cmd = './glidein_start.sh'
        print(cmd)
        p = subprocess.Popen([cmd])
        if not p.pid:
            raise Exception('failed to launch glidein')
    finally:
        os.chdir(curdir)

if __name__ == '__main__':
    main()

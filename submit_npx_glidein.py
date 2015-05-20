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

    env_wrapper = 'env_wrapper.sh'
    with open(env_wrapper,'w') as f:
        f.write('#!/bin/sh\n')
        f.write('env -i CPUS='+str(options.cpus)+' ')
        f.write('MEMORY='+str(options.memory)+' ')
        f.write('DISK='+str(options.disk)+' ')
        f.write('CVMFS=True ')
        f.write('http_proxy=http://squid.icecube.wisc.edu:3128 ')
        f.write('glidein_start.sh\n')
        
        mode = os.fstat(f.fileno()).st_mode
        mode |= 0o111
        os.fchmod(f.fileno(), mode & 0o7777)
    
    filename = 'submit.condor'
    with open(filename,'w') as f:
        f.write("""
output = out/$(Cluster).out
error = out/$(Cluster).err
log = log
notification = never
should_transfer_files = YES
when_to_transfer_output = ON_EXIT

executable = env_wrapper.sh
transfer_input_files = glidein_start.sh
+TransferOutput=""
""")

        if options.cpus:
            f.write('request_cpus='+str(options.cpus)+'\n')
        if options.memory:
            f.write('request_memory='+str(options.memory*1.1)+'\n')
        if options.disk:
            f.write('request_disk='+str(options.disk*1024*1.1)+'\n')
        if options.gpus:
            f.write('request_gpus='+str(options.gpus)+'\n')
        f.write('queue')
    
    cmd = 'condor_submit '+filename
    print(cmd)
    if subprocess.call(cmd,shell=True):
        raise Exception('failed to launch glidein')

if __name__ == '__main__':
    main()

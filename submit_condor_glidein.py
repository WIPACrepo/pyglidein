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

class SubmitCondor(object):
    def get_custom_env(self):
        return {}
    def make_env_wrapper(self,env_wrapper):
        with open(env_wrapper,'w') as f:
            f.write('#!/bin/sh\n')
            f.write('CPUS=$(grep -e "^Cpus" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}")\n')
            f.write('MEMORY=$(grep -e "^Memory" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}")\n')
            f.write('DISK=$(grep -e "^Disk" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}")\n')
            f.write('GPUS=$(grep -e "^AssignedGPUs" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}"|sed "s/\\"//g")\n')
            f.write('if ( [ -z $GPUS ] && [ ! -z $CUDA_VISIBLE_DEVICES ] ); then\n')
            f.write('  GPUS=$CUDA_VISIBLE_DEVICES\n')
            f.write('fi\n')
            f.write('if ( [ -z $GPUS ] || [ "$GPUS" = "10000" ] ); then\n')
            f.write('  GPUS=0\n')
            f.write('fi\n')
            f.write('env -i CPUS=$CPUS GPUS=$GPUS MEMORY=$MEMORY DISK=$DISK ')
            for k,v in self.get_custom_env().items():
                f.write(k+'='+v+' ')
            f.write('glidein_start.sh\n')
        
            mode = os.fstat(f.fileno()).st_mode
            mode |= 0o111
            os.fchmod(f.fileno(), mode & 0o7777)

    def make_submit_file_custom(self, file):
        pass
    
    def make_submit_file(self, filename, env_wrapper, options):
        with open(filename,'w') as f:
            f.write("""
output = /dev/null
error = /dev/null
log = log
notification = never
should_transfer_files = YES
when_to_transfer_output = ON_EXIT

executable = env_wrapper.sh
+TransferOutput=""
transfer_input_files = glidein_start.sh""")
            if options.glidein_loc:
                path = os.path.expanduser(os.path.expandvars(options.glidein_loc))
                if os.path.isfile(path):
                    f.write(','+path)
                else:
                    path = os.path.join(path,'glidein.tar.gz')
                    if os.path.isfile(path):
                        f.write(','+path)
            f.write('\n')
        
            if options.cpus:
                f.write('request_cpus='+str(options.cpus)+'\n')
            if options.memory:
                f.write('request_memory='+str(options.memory*1.1)+'\n')
            if options.disk:
                f.write('request_disk='+str(options.disk*1024*1.1)+'\n')
            if options.gpus:
                f.write('request_gpus='+str(options.gpus)+'\n')
            self.make_submit_file_custom(f)
            f.write('queue')
    
    def submit(self):
        logging.basicConfig(level=logging.INFO)
        (options,args) = glidein_parser()

        env_wrapper = 'env_wrapper.sh'
        filename = 'submit.condor'
        
        self.make_env_wrapper(env_wrapper)
        self.make_submit_file(filename,env_wrapper,options)
    
        cmd = 'condor_submit '+filename
        print(cmd)
        if subprocess.call(cmd,shell=True):
            raise Exception('failed to launch glidein')

if __name__ == '__main__':
    SubmitCondor().submit()

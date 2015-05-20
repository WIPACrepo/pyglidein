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
    
    filename = 'submit.pbs'
    with open(filename,'w') as f:
        f.write("""#!/bin/bash
#PBS -l nodes=1:ppn=2 -l mem=3000mb,pmem=3000mb
#PBS -l walltime=14:00:00
#PBS -o $HOME/glidein/out/${PBS_JOBID}.out
#PBS -e $HOME/glidein/out/${PBS_JOBID}.err
#PBS -A ngw-282-ac
#PBS -V

cd $LSCRATCH

ln -s """)
        f.write(os.path.join(options.glidein_loc,'glidein.tar.gz')+' glidein.tar.gz\n')
        f.write('ln -s '+os.path.join(options.glidein_loc,'glidein_start.sh')+' glidein_start.sh\n')
        f.write('./glidein_start.sh\n')
    
    cmd = 'qsub '+filename
    print(cmd)
    if subprocess.call(cmd,shell=True):
        raise Exception('failed to launch glidein')

if __name__ == '__main__':
    main()

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

class SubmitPBS(object):
    def get_custom_header(self):
        return "\n"
    
    def get_custom_end(self):
        return "\n"
    
    def get_custom_middle(self):
        return "\n"
    
    def get_local_dir(self):
        return ""

    def get_custom_num_cpus(self):
        return 1
    
    def write_general_header(self, file, mem = 3000, wall_time_hours = 14, 
                             num_nodes = 1, num_cpus = 2, num_gpus = 0):
        
        # Super evil hack to get around lack of correct json state for queue
        if self.get_custom_num_cpus() != 1:
            num_cpus = self.get_custom_num_cpus()
        file.write("#!/bin/bash\n")
        if num_gpus == 0:
            file.write("#PBS -l nodes=%d:ppn=%d\n" %\
                       (num_nodes, num_cpus))
        else:
            file.write("#PBS -l nodes=%d:ppn=%d:gpus=%d\n" %\
                       (num_nodes, num_cpus, num_gpus))
        file.write("#PBS -l mem=%dmb,pmem=%dmb\n" % (mem, mem))
        file.write("#PBS -l walltime=%d:00:00\n" % wall_time_hours)
        file.write("#PBS -o $HOME/glidein/out/${PBS_JOBID}.out\n")
        file.write("#PBS -e $HOME/glidein/out/${PBS_JOBID}.err\n")
    
    def write_cluster_specific(self, file, cluster_specific):
        file.write(cluster_specific)
    
    def write_glidein_variables(self, file, mem, num_cpus, has_cvmfs, num_gpus = 0):
        file.write("export MEMORY=%d\n" % mem)
        file.write("export CPUS=%d\n" % num_cpus)
        if num_gpus != 0:
            file.write("export GPUS=$CUDA_VISIBLE_DEVICES\n")
            file.write("export GPUS=\"CUDA$GPUS\"\n")
        file.write("export CVMFS=%s\n\n" % has_cvmfs)
        
    def write_glidin_part(self, file, local_dir, glidein_loc, glidein_tarball, glidein_script):
        file.write("cd %s\n\n" % local_dir)
        file.write("ln -s " + os.path.join(glidein_loc, glidein_tarball)+' %s\n' % glidein_tarball)
        file.write('ln -s '+ os.path.join(glidein_loc, glidein_script)+' %s\n' % glidein_script)
        file.write('./%s\n' % glidein_script)

    def write_submit_file(self, filename, options):
        with open(filename,'w') as f:
            self.write_general_header(f, mem = options.memory, wall_time_hours = options.walltime,
                                      num_cpus = options.cpus, num_gpus = options.gpus)
            self.write_cluster_specific(f, self.get_custom_header())
            self.write_cluster_specific(f, self.get_custom_middle())
            self.write_glidein_variables(f, mem = options.cpus*options.memory,
                                         num_cpus = options.cpus, has_cvmfs = options.cvmfs, 
                                         num_gpus = options.gpus)
            
            self.write_glidin_part(f, self.get_local_dir(), options.glidein_loc, 
                              "glidein.tar.gz", "glidein_start.sh")
            self.write_cluster_specific(f, self.get_custom_end())

    def submit(self):
        logging.basicConfig(level=logging.INFO)
        (options,args) = glidein_parser()

        filename = 'submit.pbs'

        self.write_submit_file(filename,options)

        cmd = 'qsub '+filename
        print(cmd)
        if subprocess.call(cmd,shell=True):
            raise Exception('failed to launch glidein')

class SubmitGuillimin(SubmitPBS):
    def get_local_dir(self):
        return "$LSCRATCH"
    def get_custom_header(self):
        first_line = "#PBS -A ngw-282-ac\n"
        second_line = "#PBS -V\n"
        return first_line + second_line
    def get_custom_num_cpus(self):
        return 2
        
class SubmitParallel(SubmitPBS):
    def get_local_dir(self):
        return "$TMPGLIDEIN"
    def get_custom_header(self):
        return """#PBS -q gpu\n\n"""
    def get_custom_middle(self):
        first_line = "export " + self.get_local_dir().lstrip("$") + "=/global/scratch/briedel/iceprod/scratch/${PBS_JOBID}\n\n"
        second_line = "mkdir " + self.get_local_dir() + "\n\n"
        return first_line + second_line
    # def get_custom_end(self):
    #     return "rm -rf " + self.get_local_dir() + "\n"

if __name__ == '__main__':
    # SubmitGuillimin().submit()
    SubmitParallel().submit()

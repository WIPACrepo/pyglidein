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
    
    def write_general_header(self, file, mem = 3000, wall_time_hours = 14, 
                             num_nodes = 1, num_cpus = 2, num_gpus = 0):
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
            file.write("export GPU=$CUDA_VISIBLE_DEVICES\n")
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
        
class SubmitParallel(SubmitPBS):
    def get_local_dir(self):
        return "$TMPGLIDEIN"
    def get_custom_header(self):
        return """#PBS -q gpu\n\n"""
    def get_custom_middle(self):
        first_line = "export " + self.get_local_dir().lstrip("$") + "=/global/scratch/briedel/iceprod/scratch/${PBS_JOBID}\n\n"
        second_line = "mkdir $" + self.get_local_dir() + "\n\n"
        return first_line
    def get_custom_end(self):
        return "rm -rf " + self.get_local_dir() + "\n"

if __name__ == '__main__':
    SubmitGuillimin().submit()
    # SubmitParallel().submit()

# def guillimin():
#     logging.basicConfig(level=logging.INFO)
#     (options,args) = glidein_parser()
#
#     print options
#
#     filename = 'submit.pbs'
#     with open(filename,'w') as f:
#         write_header(f, )
#         write_output_error(f)
#         write_glidein_variables(f)
#         write_glidin_part(f)
        
#         f.write("""#!/bin/bash
# #PBS -l nodes=1:ppn=2 -l mem=3000mb,pmem=3000mb
# #PBS -l walltime=14:00:00
# #PBS -o $HOME/glidein/out/${PBS_JOBID}.out
# #PBS -e $HOME/glidein/out/${PBS_JOBID}.err
# #PBS -A ngw-282-ac
# #PBS -V
#
# cd $LSCRATCH
#
# export MEMORY=5000
# export CPUS=2
# export CVMFS=True
# """)
#         write_glidin(f)

    # cmd = 'qsub '+filename
    # print(cmd)
    # if subprocess.call(cmd,shell=True):
    #     raise Exception('failed to launch glidein')

# def parallel():
#     logging.basicConfig(level=logging.INFO)
#     (options,args) = glidein_parser()
#
#     filename = 'submit.pbs'
#
#     with open(filename,'w') as f:
        


# def gpu_parallel():
#     logging.basicConfig(level=logging.INFO)
#     (options,args) = glidein_parser()
#
#     filename = 'submit.pbs'
#     with open(filename,'w') as f:
#         f.write("""#!/bin/bash
# #PBS -S /bin/bash
# #PBS -q gpu
# #PBS -l nodes=1:ppn=1:gpus=1
# #PBS -l walltime=14:00:00
# #PBS -o $HOME/glidein/out/${PBS_JOBID}.out
# #PBS -e $HOME/glidein/out/${PBS_JOBID}.err
#
# export TMP=/global/scratch/briedel/iceprod/scratch/${PBS_JOBID}
#
# mkdir $TMP
#
# cd $TMP
#
# export MEMORY=2200
# export CPUS=1
# export CVMFS=True
# export GPU=$CUDA_VISIBLE_DEVICES
#
# ln -s """)
#         f.write(os.path.join(options.glidein_loc,'glidein.tar.gz')+' glidein.tar.gz\n')
#         f.write('ln -s '+os.path.join(options.glidein_loc,'glidein_start.sh')+' glidein_start.sh\n')
#         f.write('./glidein_start.sh\n')
#         f.write("rm -rf $TMP")
#
#     cmd = 'qsub '+filename
#     print(cmd)
#     if subprocess.call(cmd,shell=True):
#         raise Exception('failed to launch glidein')
#
# def gpu_guillimin():
#     logging.basicConfig(level=logging.INFO)
#     (options,args) = glidein_parser()
#
#     filename = 'submit.pbs'
#     with open(filename,'w') as f:
#         f.write("""#!/bin/bash
# #PBS -l nodes=1:ppn=1:gpus=1
# #PBS -l walltime=14:00:00
# #PBS -o $HOME/glidein/out/${PBS_JOBID}.out
# #PBS -e $HOME/glidein/out/${PBS_JOBID}.err
# #PBS -A ngw-282-ac
# #PBS -V
#
# cd $LSCRATCH
#
# export MEMORY=2200
# export CPUS=1
# export CVMFS=True
# export GPU=$CUDA_VISIBLE_DEVICES
#
# ln -s """)
#         f.write(os.path.join(options.glidein_loc,'glidein.tar.gz')+' glidein.tar.gz\n')
#         f.write('ln -s '+os.path.join(options.glidein_loc,'glidein_start.sh')+' glidein_start.sh\n')
#         f.write('./glidein_start.sh\n')
#
#     cmd = 'qsub '+filename
#     print(cmd)
#     if subprocess.call(cmd,shell=True):
#         raise Exception('failed to launch glidein')
# 
# def main():
#     options, args = glidein_parser()
#     if options.gpus > 0 and options.cluster == "parallel":
#         gpu_parallel()
#     elif options.gpus > 0:
#         gpu_guillimin()
#     else:
#         guillimin()
#
# if __name__ == '__main__':
#     main()

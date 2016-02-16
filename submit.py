#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

import os
import sys
import time
import platform
import subprocess
import logging
import tempfile

# class Submit(object):
#     def __init__(self, config):
#         self.config = config
#
#     def submit(self):
#         pass
            
class SubmitPBS(object):
    def __init__(self, config):
        self.config = config
        
    def write_general_header(self, file, mem = 3000, wall_time_hours = 14, 
                             num_nodes = 1, num_cpus = 2, num_gpus = 0):
        file.write("#!/bin/bash\n")
        if num_gpus == 0:
            file.write("#PBS -l nodes=%d:ppn=%d\n" %\
                       (num_nodes, num_cpus))
        else:
            file.write("#PBS -l nodes=%d:ppn=%d:gpus=%d\n" %\
                       (num_nodes, num_cpus, num_gpus))
        if num_gpus == 0:
            file.write("#PBS -l mem=%dmb,pmem=%dmb\n" % (mem / num_cpus, mem / num_cpus))
        else:
            file.write("#PBS -l mem=%dmb,pmem=%dmb\n" % ((mem / num_cpus)*1.1, (mem / num_cpus)*1.1))
        file.write("#PBS -l mem=%dmb,pmem=%dmb\n" % (mem / num_cpus, mem / num_cpus))
        file.write("#PBS -l walltime=%d:00:00\n" % wall_time_hours)
        file.write("#PBS -o $HOME/glidein/out/${PBS_JOBID}.out\n")
        file.write("#PBS -e $HOME/glidein/out/${PBS_JOBID}.err\n")
    
    def write_cluster_specific(self, file, cluster_specific):
        file.write(cluster_specific + "\n\n")
    
    def write_glidein_variables(self, file, mem, num_cpus, has_cvmfs, num_gpus = 0):
        if num_gpus != 0:
            file.write("export MEMORY=%d\n" % int(mem*1.1))
        else:
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

    def write_submit_file(self, filename, state):
        with open(filename,'w') as f:
            num_cpus = state["cpus"]
            while state["memory"] > (self.config["Cluster"]["mem_per_core"]*num_cpus) and state["gpus"] == 0:
                num_cpus += 1
            if state["gpus"] > 0:
                mem = state["memory"]
            elif num_cpus*self.config["Cluster"]["mem_per_core"] >= state["memory"]:
                mem = num_cpus*self.config["Cluster"]["mem_per_core"]
                
            self.write_general_header(f, mem = mem, 
                                      wall_time_hours = self.config["Cluster"]["walltime_hrs"],
                                      num_cpus = num_cpus, num_gpus = state["gpus"])
            if "custom_header" in self.config["SubmitFile"]:
                self.write_cluster_specific(f, self.config["SubmitFile"]["custom_header"])
            if "custom_middle" in self.config["SubmitFile"]:
                self.write_cluster_specific(f, self.config["SubmitFile"]["custom_middle"])
            
            self.write_glidein_variables(f, mem = mem,
                                         num_cpus = state["cpus"], has_cvmfs = state["cvmfs"], 
                                         num_gpus = state["gpus"])
            self.write_glidin_part(f, self.config["SubmitFile"]["local_dir"], self.config["Glidein"]["loc"], 
                                   self.config["Glidein"]["tarball"], self.config["Glidein"]["executable"])
            if "custom_end" in self.config["SubmitFile"]:
                self.write_cluster_specific(f, self.config["SubmitFile"]["custom_end"])
            
    def submit(self, state):
        logging.basicConfig(level=logging.INFO)
        # (options,args) = glidein_parser()

        filename = self.config["SubmitFile"]["filename"]
        
        self.write_submit_file(filename, state)

        cmd = self.config["Cluster"]["submit_command"] + " " + filename
        print(cmd)
        if subprocess.call(cmd,shell=True):
            raise Exception('failed to launch glidein')

class SubmitCondor(object):
    def __init__(self, config):
        self.config = config
        
    def write_line(self, file, line):
        file.write(line+"\n")
        
    def make_env_wrapper(self, env_wrapper):
        with open(env_wrapper,'w') as f:
            self.write_line(f, '#!/bin/sh')
            self.write_line(f, 'CPUS=$(grep -e "^Cpus" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}")')
            self.write_line(f, 'MEMORY=$(grep -e "^Memory" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}")')
            self.write_line(f, 'DISK=$(grep -e "^Disk" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}")')
            self.write_line(f, 'GPUS=$(grep -e "^AssignedGPUs" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}"|sed "s/\\"//g")')
            self.write_line(f, 'if ( [ -z $GPUS ] && [ ! -z $CUDA_VISIBLE_DEVICES ] ); then')
            self.write_line(f, '  GPUS=$CUDA_VISIBLE_DEVICES')
            self.write_line(f, 'fi')
            self.write_line(f, 'GPUS_NO_DIGITS=$(echo $GPUS | sed \'s/[0-9]*//g\'')
            self.write_line(f, 'if [ "${GPUS_NO_DIGITS}" = "" ]; then')
            self.write_line(f, '    GPUS="CUDA${GPUS}"\n')
            self.write_line(f, 'fi')
            self.write_line(f, 'if ( [ -z $GPUS ] || [ "$GPUS" = "10000" ] ); then')
            self.write_line(f, '  GPUS=0\n')
            self.write_line(f, 'fi')
            self.write_line(f, 'env -i CPUS=$CPUS GPUS=$GPUS MEMORY=$MEMORY DISK=$DISK')
            if "CustomEnv" in self.config:
                for k,v in self.config["CustomEnv"].items():
                    self.write_line(f, k + '=' + v + ' ')
            self.write_line(f, '%s' % self.config["Glidein"]["executable"])
        
            mode = os.fstat(f.fileno()).st_mode
            mode |= 0o111
            os.fchmod(f.fileno(), mode & 0o7777)

    # def make_submit_file_custom(self, file):
    #     pass
    
    def make_submit_file(self, filename, env_wrapper, state):
        with open(filename,'w') as f:
            if "custom_header" in self.config["SubmitFile"]:
                f.write(self.config["SubmitFile"]["custom_header"])
            self.write_line(f, "output = /dev/null")
            self.write_line(f, "error = /dev/null")
            self.write_line(f, "log = log")
            self.write_line(f, "notification = never")
            self.write_line(f, "should_transfer_files = YES")
            self.write_line(f, "when_to_transfer_output = ON_EXIT")
            self.write_line(f, "")
            self.write_line(f, "executable = %s" % env_wrapper)
            self.write_line(f, "+TransferOutput=\"\"")
            f.write("transfer_input_files = glidein_start.sh")
            if "custom_body" in self.config["SubmitFile"]:
                f.write(self.config["SubmitFile"]["custom_body"])
            if "loc" in self.config["Glidein"]:
                path = os.path.expanduser(os.path.expandvars(self.config["Glidein"]["loc"]))
                if os.path.isfile(path):
                    f.write(','+path)
                else:
                    path = os.path.join(path, self.config["Glidein"]["tarball"])
                    if os.path.isfile(path):
                        f.write(','+path)
            f.write('\n')
        
            if state["cups"] != 0:
                self.write_line(f, 'request_cpus=%d' % state["cups"])
            if state["memory"] != 0:
                self.write_line(f, 'request_memory=%d' % int(state["memory"]*1.1))
            if state["disk"] != 0:
                self.write_line(f, 'request_disk=%d' % int(state["disk"]*1024*1.1))
            if state["gups"] != 0:
                self.write_line(f, 'request_gpus=%d' % int(state["gups"]))
            # self.make_submit_file_custom(f)
            if "custom_footer" in self.config["SubmitFile"]:
                f.write(self.config["SubmitFile"]["custom_footer"])
            f.write('queue')
    
    def submit(self, state):
        logging.basicConfig(level=logging.INFO)
        # (options,args) = glidein_parser()
        
        self.make_env_wrapper(self.config["SubmitFile"]["env_wrapper_name"])
        self.make_submit_file(self.config["SubmitFile"]["filename"],
                              self.config["SubmitFile"]["env_wrapper_name"],
                              state)
                              
        cmd = self.config["Cluster"]["submit_command"]+self.config["SubmitFile"]["filename"]
        print(cmd)
        if subprocess.call(cmd,shell=True):
            raise Exception('failed to launch glidein')
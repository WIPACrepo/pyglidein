#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

import os
import sys
import time
import platform
import subprocess
import logging
import tempfile

class Submit(object):
    """
    Base class for the submit classes
    Mostly to provide future expansion for common functions
    """
    def __init__(self, config):
        """
        Initialize

        Args:
            config: cluster config dict for cluster
        """
        self.config = config

    def submit(self):
        raise NotImplementedError()

    def write_line(self, f, line):
        f.write(line+"\n")

    def get_executable(self):
        executable = 'glidein_start.sh'
        if 'executable' in self.config['Glidein']:
            executable = self.config["Glidein"]["executable"]
        return executable

class SubmitPBS(Submit):
    """Submit a PBS / Torque job"""

    def write_general_header(self, f, mem=3000, walltime_hours=14,
                             num_nodes=1, num_cpus=1, num_gpus=0):
        """
        Writing the header for a PBS submission script.
        Most of the pieces needed to tell PBS what resources
        are being requested.

        Args:
            f: python file object
            mem: requested memory
            walltime_hours: requested wall time
            num_nodes: requested number of nodes
            num_cpus: requested number of cpus
            num_gpus: requested number of gpus
        """
        self.write_line(f, "#!/bin/bash")
        # Add the necessary gpu request tag if we need gpus.
        if num_gpus == 0:
            self.write_line(f, "#PBS -l nodes=%d:ppn=%d" %\
                            (num_nodes, num_cpus))
        else:
            self.write_line(f, "#PBS -l nodes=%d:ppn=%d:gpus=%d" %\
                            (num_nodes, num_cpus, num_gpus))
        self.write_line(f, "#PBS -l mem=%dmb,pmem=%dmb" % (mem, mem))
        self.write_line(f, "#PBS -l walltime=%d:00:00" % walltime_hours)
        if ('Mode' in self.config and 'debug' in self.config['Mode']
           and self.config["Mode"]["debug"]):
            outdir = os.path.join(os.getcwd(),'out')
            if not os.path.isdir(outdir):
                os.mkdir(outdir)
            self.write_line(f, "#PBS -o %s/${PBS_JOBID}.out"%outdir)
            self.write_line(f, "#PBS -e %s/${PBS_JOBID}.err"%outdir)
        else:
            self.write_line(f, "#PBS -o /dev/null")
            self.write_line(f, "#PBS -e /dev/null")

    def write_glidein_variables(self, f, mem=None, walltime_hours=None,
                                num_cpus=None, num_gpus=None):
        """
        Writing the header for a PBS submission script.
        Most of the pieces needed to tell PBS what resources
        are being requested.

        Args:
            f: python file object
            mem: memory provided for glidein
            walltime_hours: lifetime of glidein in hours
            cpus: number of cpus provided
            gpus: number of cpus provided
        """
        if mem:
            self.write_line(f, "export MEMORY=%d" % mem)
        if walltime_hours:
            self.write_line(f, "export WALLTIME=%d" % (walltime_hours*3600))
        if num_cpus:
            self.write_line(f, "export CPUS=%d" % num_cpus)
        if num_gpus:
            self.write_line(f, 'if [ "$CUDA_VISIBLE_DEVICES" = "0" ]; then')
            self.write_line(f, '  export GPUS="CUDA${CUDA_VISIBLE_DEVICES}"')
            self.write_line(f, 'else')
            self.write_line(f, '  export GPUS=$CUDA_VISIBLE_DEVICES')
            self.write_line(f, 'fi')

        if 'site' in self.config['Glidein']:
            self.write_line(f, 'export SITE="%s"' % self.config['Glidein']['site'])
        if 'cluster' in self.config['Glidein']:
            self.write_line(f, 'export CLUSTER="%s"' % self.config['Glidein']['cluster'])

    def write_glidein_part(self, f, local_dir=None, glidein_tarball=None,
                           glidein_script=None, glidein_loc=None):
        """
        Writing the pieces needed to execute the glidein

        Args:
            f: python file object
            local_dir: what is the local directory
            glidein_loc: directory of the glidein pieces
            glidein_tarball: file name of tarball
            glidein_script: file name of glidein start script
        """
        self.write_line(f, "cd %s\n" % local_dir)
        if not glidein_loc:
            glidein_loc = os.getcwd()
        if glidein_tarball:
            self.write_line(f, "ln -s %s %s" % (os.path.join(glidein_loc, glidein_tarball), glidein_tarball))
        self.write_line(f, 'ln -s %s %s' % (os.path.join(glidein_loc, glidein_script), glidein_script))
        self.write_line(f, './%s' % glidein_script)

    def write_submit_file(self, filename, state):
        """
        Writing the submit file

        Args:
            filename: name of PBS script to create
            state: what resource requirements a given glidein has
        """
        with open(filename, 'w') as f:
            num_cpus = state["cpus"]
            mem_advertised = int(state["memory"]*1.1)
            mem_requested = mem_advertised
            num_gpus = state["gpus"]

            mem_per_core = 2000
            if 'mem_per_core' in self.config['Cluster']:
                mem_per_core = self.config['Cluster']['mem_per_core']
            if num_gpus:
                if mem_requested > mem_per_core:
                    # just ask for the max mem, and hope that's good enough
                    mem_requested = mem_per_core
            else:
                # It is easier to request more cpus rather than more memory
                while mem_requested > mem_per_core:
                    num_cpus += 1
                    mem_requested = mem_advertised/num_cpus
            walltime = int(self.config["Cluster"]["walltime_hrs"])

            self.write_general_header(f, mem=mem_requested, num_cpus=num_cpus,
                                      num_gpus=num_gpus,
                                      walltime_hours=walltime)

            if "custom_header" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_header"])
            if "custom_middle" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_middle"])

            self.write_glidein_variables(f, mem=mem_advertised,
                                         num_cpus=num_cpus, num_gpus=num_gpus,
                                         walltime_hours=walltime)

            kwargs = {
                'local_dir': self.config["SubmitFile"]["local_dir"],
                'glidein_script': self.get_executable(),
            }
            if "tarball" in self.config["Glidein"]:
                kwargs['glidein_tarball'] = self.config["Glidein"]["tarball"]
                kwargs['glidein_loc'] = self.config["Glidein"]["loc"]
            self.write_glidein_part(f, **kwargs)

            if "custom_end" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_end"])

    def submit(self, state):
        """
        Submitting the PBS script

        Args:
            state: what resource requirements a given glidein has
        """
        submit_filename = 'submit.pbs'
        if 'filename' in self.config["SubmitFile"]:
            submit_filename = self.config["SubmitFile"]["filename"]

        self.write_submit_file(submit_filename, state)

        cmd = self.config["Cluster"]["submit_command"] + " " + submit_filename
        print(cmd)
        if not ('Mode' in self.config and 'dryrun' in self.config['Mode'] and
                self.config['Mode']['dryrun']):
            if subprocess.call(cmd,shell=True):
                raise Exception('failed to launch glidein')

class SubmitSLURM(SubmitPBS):
    """SLURM is similar to PBS, but with different headers"""

    def write_general_header(self, f, mem=3000, walltime_hours=14,
                             num_nodes=1, num_cpus=1, num_gpus=0):
        """
        Writing the header for a SLURM submission script.
        Most of the pieces needed to tell SLURM what resources
        are being requested.

        Args:
            f: python file object
            mem: requested memory
            walltime_hours: requested wall time
            num_nodes: requested number of nodes
            num_cpus: requested number of cpus
            num_gpus: requested number of gpus
        """
        self.write_line(f, "#!/bin/bash")
        self.write_line(f, '#SBATCH --job-name="glidein"')
        self.write_line(f, '#SBATCH --nodes=%d'%num_nodes)
        self.write_line(f, '#SBATCH --ntasks-per-node=%d'%num_cpus)
        self.write_line(f, '#SBATCH --mem=%d'%(mem*1.1))
        if num_gpus:
            self.write_line(f, "#SBATCH --partition=gpu-shared")
            self.write_line(f, "#SBATCH --gres=gpu:%d"%num_gpus)
        else:
            self.write_line(f, "#SBATCH --partition=shared")
        self.write_line(f, "#SBATCH --time=%d:00:00" % walltime_hours)
        if self.config["Mode"]["debug"]:
            self.write_line(f, "#SBATCH --output=%s/out/%%j.out"%os.getcwd())
            self.write_line(f, "#SBATCH --error=%s/out/%%j.err"%os.getcwd())
        else:
            self.write_line(f, "#SBATCH --output=/dev/null")
            self.write_line(f, "#SBATCH --error=/dev/null")
        self.write_line(f, "#SBATCH --export=ALL")

class SubmitCondor(Submit):
    """Submit an HTCondor job"""

    def make_env_wrapper(self, env_wrapper):
        """
        Creating wrapper execute script for
        HTCondor submit file

        Args:
            env_wrapper: name of wrapper script
        """
        with open(env_wrapper, 'w') as f:
            self.write_line(f, '#!/bin/sh')
            self.write_line(f, 'CPUS=$(grep -e "^Cpus" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}")')
            self.write_line(f, 'MEMORY=$(grep -e "^Memory" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}")')
            self.write_line(f, 'DISK=$(grep -e "^Disk" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}")')
            self.write_line(f, 'GPUS=$(grep -e "^AssignedGPUs" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}"|sed "s/\\"//g")')
            self.write_line(f, 'if ( [ -z $GPUS ] && [ ! -z $CUDA_VISIBLE_DEVICES ] ); then')
            self.write_line(f, '  GPUS=$CUDA_VISIBLE_DEVICES')
            self.write_line(f, 'fi')
            self.write_line(f, 'GPUS_NO_DIGITS=$(echo $GPUS | sed \'s/[0-9]*//g\')')
            self.write_line(f, 'if [ "${GPUS_NO_DIGITS}" = "${GPUS}" ]; then')
            self.write_line(f, '    GPUS=""')
            self.write_line(f, 'elif [ -z $GPUS_NO_DIGITS ]; then')
            self.write_line(f, '    GPUS="CUDA${GPUS}"')
            self.write_line(f, 'fi')
            self.write_line(f, 'if ( [ -z $GPUS ] || [ "$GPUS" = "10000" ] || [ "$GPUS" = "CUDA10000" ] ); then')
            self.write_line(f, '  GPUS=0')
            self.write_line(f, 'fi')
            if 'site' in self.config['Glidein']:
                self.write_line(file, 'SITE="%s"' % self.config['Glidein']['site'])
            if 'cluster' in self.config['Glidein']:
                self.write_line(file, 'CLUSTER="%s"' % self.config['Glidein']['cluster'])
            f.write('env -i CPUS=$CPUS GPUS=$GPUS MEMORY=$MEMORY DISK=$DISK ')
            if 'site' in self.config['Glidein']:
                f.write('SITE=$SITE ')
            if 'cluster' in self.config['Glidein']:
                f.write('CLUSTER=$CLUSTER ')
            if "CustomEnv" in self.config:
                for k, v in self.config["CustomEnv"].items():
                    f.write(k + '=' + v + ' ')
            f.write(str(self.get_executable()))

            mode = os.fstat(f.fileno()).st_mode
            mode |= 0o111
            os.fchmod(f.fileno(), mode & 0o7777)

    def make_submit_file(self, filename, env_wrapper, state):
        """
        Creating HTCondor submit file

        Args:
            filename: name of HTCondor submit file
            env_wrapper: name of wrapper script
            state: what resource requirements a given glidein has
        """
        with open(filename, 'w') as f:
            if "custom_header" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_header"])

            if ('Mode' in self.config and 'debug' in self.config['Mode']
               and self.config["Mode"]["debug"]):
                outdir = os.path.join(os.getcwd(),'out')
                if not os.path.isdir(outdir):
                    os.mkdir(outdir)
                self.write_line(f, "output = %s/$(Cluster).out"%outdir)
                self.write_line(f, "error = %s/$(Cluster).out"%outdir)
            else:
                self.write_line(f, "output = /dev/null")
                self.write_line(f, "error = /dev/null")
            self.write_line(f, "log = log")
            self.write_line(f, "notification = never")
            self.write_line(f, "should_transfer_files = YES")
            self.write_line(f, "when_to_transfer_output = ON_EXIT")
            self.write_line(f, "")
            self.write_line(f, "executable = %s" % env_wrapper)
            self.write_line(f, "+TransferOutput=\"\"")

            # get input files
            infiles = []
            executable = self.get_executable()
            if not os.path.isfile(executable):
                raise Exception("no executable provided")
            infiles.append(executable)
            if "tarball" in self.config["Glidein"]:
                if not os.path.isfile(self.config["Glidein"]["tarball"]):
                    raise Exception("provided tarball does not exist")
                infiles.append(self.config["Glidein"]["tarball"])
            self.write_line(f, "transfer_input_files = %s"%(','.join(infiles)))

            if "custom_middle" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_middle"])

            if state["cpus"] != 0:
                self.write_line(f, 'request_cpus=%d' % state["cpus"])
            if state["memory"] != 0:
                self.write_line(f, 'request_memory=%d' % int(state["memory"]*1.1))
            if state["disk"] != 0:
                self.write_line(f, 'request_disk=%d' % int(state["disk"]*1024*1.1))
            if state["gpus"] != 0:
                self.write_line(f, 'request_gpus=%d' % int(state["gpus"]))

            if "custom_footer" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_footer"])

            self.write_line(f, 'queue')

    def submit(self, state):
        submit_filename = 'submit.condor'
        if 'filename' in self.config["SubmitFile"]:
            submit_filename = self.config["SubmitFile"]["filename"]
        env_filename = 'env_wrapper.sh'
        if 'env_wrapper_name' in self.config['SubmitFile']:
            env_filename = self.config["SubmitFile"]["env_wrapper_name"]
        self.make_env_wrapper(env_filename)
        self.make_submit_file(submit_filename,
                              env_filename,
                              state)

        cmd = self.config["Cluster"]["submit_command"] + " " + submit_filename
        print(cmd)
        if subprocess.call(cmd, shell=True):
            raise Exception('failed to launch glidein')

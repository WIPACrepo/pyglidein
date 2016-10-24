#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

import os
import sys
import time
import platform
import subprocess
import logging
import tempfile
import shutil
import glob

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
        """
        Wrapper function so we dont have to write \n a million times
        
        Args:
            f: File handle
            line: Line to be written to file
        """
        f.write(line+"\n")

    def get_glidein_script(self):
        """
        Get the glidein startup script.

        Returns:
            String that is the location of the script
        """
        glidein_script = 'glidein_start.sh'
        if 'glidein_script' in self.config['Glidein']:
            glidein_script = self.config['Glidein']['glidein_script']
        return glidein_script

    def get_resource_limit_scale(self, key, sec="SubmitFile"):
        """
        Return scaling factor for job limit resources
        (e.g. memory, disk space).

        Args:
            key: key to evaluate in config file
            sec: section to evaluate in config file
                 (default: 'SubmitFile')
        Returns:
            A float that is the scaling factor for a resource
        """
        try:
            # look for entry and check type
            scale = self.config[sec][key]
            if not (isinstance(scale, int) or
                    isinstance(scale, float)):
                raise TypeError()
        except:
            # return 1 if no entry or invalid type found
            scale = 1

        return scale
    
    def cleanup(self, cmd, direc):
        pass

class SubmitPBS(Submit):
    """Submit a PBS / Torque job"""

    option_tag = "#PBS"

    def write_option(self, f, line):
        self.write_line(f, self.option_tag+" "+line)

    def write_general_header(self, f, mem=3000, walltime_hours=14, disk=1,
                             num_nodes=1, num_cpus=1, num_gpus=0,
                             num_jobs=0):
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
            self.write_option(f, "-l nodes=%d:ppn=%d" %\
                            (num_nodes, num_cpus))
        else:
            self.write_option(f, "-l nodes=%d:ppn=%d:gpus=%d" %\
                            (num_nodes, num_cpus, num_gpus))
        if ("Cluster" in self.config and 'pmem_only' in self.config['Cluster']
            and self.config["Cluster"]["pmem_only"]):
            self.write_option(f, "-l pmem=%dmb" % mem)
        else:
            self.write_option(f, "-l pmem=%dmb,mem=%dmb" % (mem,mem*num_cpus))
        self.write_option(f, "-l walltime=%d:00:00" % walltime_hours)
        if ('Mode' in self.config and 'debug' in self.config['Mode']
           and self.config["Mode"]["debug"]):
            outdir = os.path.join(os.getcwd(),'out')
            if not os.path.isdir(outdir):
                os.mkdir(outdir)
            self.write_option(f, "-o %s/${PBS_JOBID}.out"%outdir)
            self.write_option(f, "-e %s/${PBS_JOBID}.err"%outdir)
        else:
            self.write_option(f, "-o /dev/null")
            self.write_option(f, "-e /dev/null")
        if num_jobs > 0:
            self.write_option(f, "-t 0-%d" % num_jobs)

    def write_glidein_variables(self, f, mem=1000, walltime_hours=12,
                                num_cpus=1, num_gpus=0, disk=1):
        """
        Tell the glidein what resources it has.

        Args:
            f: python file object
            mem: memory provided for glidein
            walltime_hours: lifetime of glidein in hours
            cpus: number of cpus provided
            gpus: number of cpus provided
            disk: disk provided for glidein
        """
        self.write_line(f, "MEMORY=%d" % mem)
        self.write_line(f, "WALLTIME=%d" % (walltime_hours*3600))
        self.write_line(f, "CPUS=%d" % num_cpus)
        self.write_line(f, "DISK=%d" % (disk*1024))
        if num_gpus:
            self.write_line(f, 'if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then')
            self.write_line(f, '  GPUS="CUDA${CUDA_VISIBLE_DEVICES}"')
            self.write_line(f, 'else')
            self.write_line(f, '  GPUS=$CUDA_VISIBLE_DEVICES')
            self.write_line(f, 'fi')
        else:
            self.write_line(f, 'GPUS=0')

        if 'site' in self.config['Glidein']:
            self.write_line(f, 'SITE="%s"' % self.config['Glidein']['site'])
        if 'cluster' in self.config['Glidein']:
            self.write_line(f, 'CLUSTER="%s"' % self.config['Glidein']['cluster'])

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
        self.write_line(f, 'CLEANUP=0')
        self.write_line(f, 'LOCAL_DIR=%s' % local_dir)
        self.write_line(f, 'if [ ! -d $LOCAL_DIR ]; then')
        self.write_line(f, '    mkdir -p $LOCAL_DIR')
        self.write_line(f, '    CLEANUP=1')
        self.write_line(f, 'fi')
        self.write_line(f, 'cd $LOCAL_DIR')
        if not glidein_loc:
            glidein_loc = os.getcwd()
        if glidein_tarball:
            self.write_line(f, 'ln -fs %s %s' % (glidein_tarball, os.path.basename(glidein_tarball)))
        self.write_line(f, 'ln -fs %s %s' % (os.path.join(glidein_loc, glidein_script), glidein_script))
        if not os.path.isfile(os.path.join(glidein_loc, glidein_script)):
            raise Exception("glidein_script %s does not exist!"%os.path.join(glidein_loc, glidein_script))

        f.write('env -i CPUS=$CPUS GPUS=$GPUS MEMORY=$MEMORY DISK=$DISK WALLTIME=$WALLTIME ')
        if 'site' in self.config['Glidein']:
            f.write('SITE=$SITE ')
        if 'cluster' in self.config['Glidein']:
            f.write('CLUSTER=$CLUSTER ')
        if "CustomEnv" in self.config:
            for k, v in self.config["CustomEnv"].items():
                f.write(k + '=' + v + ' ')
        executable = ''
        if 'executable' in self.config['SubmitFile']:
            executable = self.config['SubmitFile']['executable']
        self.write_line(f, '%s ./%s' % (executable, glidein_script))

        self.write_line(f, 'if [ $CLEANUP = 1 ]; then')
        self.write_line(f, '    rm -rf $LOCAL_DIR')
        self.write_line(f, 'fi')

    def get_cores_for_memory(self, num_cpus_advertised, num_gpus_advertised, mem_advertised):
        """
        Scale number of cores to satisfy memory request, assuming fixed amount
        of memory per core.
        
        Args:
            num_cpus_advertised: the number of cores explicitly requested
            num_gpus_advertised: the number of GPUs explicitly requested
            mem_advertised: the total amount of memory requested
        Returns:
            num_cpus: number of cores to request
            mem_requested: amount of memory to request per core
            mem_advertised: amount of memory the Condor slot should advertise
        """
        num_cpus = num_cpus_advertised
        mem_requested = mem_advertised
        mem_per_core = 2000
        if 'mem_per_core' in self.config['Cluster']:
            mem_per_core = self.config['Cluster']['mem_per_core']
        if num_gpus_advertised:
            if mem_requested > mem_per_core:
                # just ask for the max mem, and hope that's good enough
                mem_requested = mem_per_core
                mem_advertised = mem_requested
        else:
            # It is easier to request more cpus rather than more memory
            while mem_requested > mem_per_core:
                num_cpus += 1
                mem_requested = mem_advertised/num_cpus
        
        return num_cpus, mem_requested, mem_advertised

    def write_submit_file(self, filename, state, group_jobs):
        """
        Writing the submit file

        Args:
            filename: name of PBS script to create
            state: what resource requirements a given glidein has
        """
        with open(filename, 'w') as f:
            if 'whole_node' in self.config['Cluster']:
                num_cpus = int(self.config['Cluster']['whole_node_cpus'])
                mem_requested = mem_advertised = int(self.config['Cluster']['whole_node_memory'])
                disk = int(self.config['Cluster']['whole_node_disk'])
                if 'whole_node_gpus' in self.config['Cluster']:
                    num_gpus = int(self.config['Cluster']['whole_node_gpus'])
                else:
                    num_gpus = 0
            else:
                num_cpus = state["cpus"]
                mem_safety_margin = 1.05*self.get_resource_limit_scale("mem_safety_scale")
                mem_advertised = int(state["memory"]*mem_safety_margin)
                num_gpus = state["gpus"]
                disk = state["disk"]*1.1

                num_cpus, mem_requested, mem_advertised = self.get_cores_for_memory(num_cpus, num_gpus, mem_advertised)

            walltime = int(self.config["Cluster"]["walltime_hrs"])

            self.write_general_header(f, mem=mem_requested, num_cpus=num_cpus,
                                      num_gpus=num_gpus, walltime_hours=walltime,
                                      disk=disk,
                                      num_jobs = state["count"] if group_jobs else 0)

            if "custom_header" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_header"])
            if "custom_middle" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_middle"])

            self.write_glidein_variables(f, mem=mem_advertised,
                                         num_cpus=num_cpus, num_gpus=num_gpus,
                                         walltime_hours=walltime, disk=disk)

            kwargs = {
                'local_dir': self.config["SubmitFile"]["local_dir"],
                'glidein_script': self.get_glidein_script(),
            }
            if "loc" in self.config["Glidein"]:
                kwargs['glidein_loc'] = self.config["Glidein"]["loc"]
            if "tarball" in self.config["Glidein"]:
                if "loc" in self.config["Glidein"]:
                    glidein_tarball = os.path.join(self.config["Glidein"]["loc"], 
                                                   self.config["Glidein"]["tarball"])
                else:
                    glidein_tarball = self.config["Glidein"]["tarball"]

                if os.path.isfile(glidein_tarball):
                    kwargs['glidein_tarball'] = glidein_tarball
                else:
                    raise Exception("The tarball you provided does not exist")
            self.write_glidein_part(f, **kwargs)

            if "custom_end" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_end"])

    def submit(self, state):
        """
        Writing submit file and submitting a job for PBS-like batch managers

        Args:
            state: what resource requirements a given glidein has
        """
        submit_filename = 'submit.pbs'
        if 'filename' in self.config["SubmitFile"]:
            submit_filename = self.config["SubmitFile"]["filename"]
        
        group_jobs = ("group_jobs" in self.config["Cluster"] and
                      self.config["Cluster"]["group_jobs"] and
                      "count" in state)

        self.write_submit_file(submit_filename, state, group_jobs)
        num_submits = 1 if group_jobs else state["count"] if "count" in state else 1
        for i in xrange(num_submits):
            cmd = self.config["Cluster"]["submit_command"] + " " + submit_filename
            print(cmd)
            if not ('Mode' in self.config and 'dryrun' in self.config['Mode'] and
                    self.config['Mode']['dryrun']):
                if subprocess.call(cmd,shell=True):
                    raise Exception('failed to launch glidein')

    def cleanup(self, cmd, direc):
        """
        Cleans up temporary directories that were created on a network file system that were not 
        deleted by the job itself. Checks whether the job ID used to identify a temporary directory
        is still in the queue. If it is not, the directory gets deleted.

        Args:
            cmd: Command needed to query about which jobs are running for the user
            direc: Which directory to look for the temporory directories
        """
        cmd = cmd[:-6]
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        d = p.communicate()[0]
        job_ids = set([job.split(" ")[0] for job in d.splitlines() if "[" not in job.split(" ")[0] ])
        dir_ids = set([dir.split("/")[-1].split(".")[0] for dir in glob.glob(os.path.join(os.path.expandvars(direc), "*"))])
        for ids in (dir_ids - job_ids):
            logging.info("Deleting %s", ids)
            shutil.rmtree(glob.glob(os.path.join(os.path.expandvars(direc), ids + "*"))[0])

class SubmitSLURM(SubmitPBS):
    """SLURM is similar to PBS, but with different headers"""
    
    option_tag = "#SBATCH"
    
    def write_general_header(self, f, mem=3000, walltime_hours=14, disk=1,
                             num_nodes=1, num_cpus=1, num_gpus=0, 
                             num_jobs=0):
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
            num_jobs: requested number of jobs
        """
        if num_jobs > 1:
            raise Exception('more than one job not supported')
        self.write_line(f, "#!/bin/bash")
        self.write_option(f, '--job-name="glidein"')
        self.write_option(f, '--nodes=%d'%num_nodes)
        self.write_option(f, '--ntasks-per-node=%d'%num_cpus)
        self.write_option(f, '--mem=%d'%(mem))
        if num_gpus:
            self.write_option(f, "--gres=gpu:%d"%num_gpus)
        if "partition" in self.config['Cluster']:
            self.write_option(f, "--partition=%s" % self.config['Cluster']["partition"])
        self.write_option(f, "--time=%d:00:00" % walltime_hours)
        if self.config["Mode"]["debug"]:
            log_dir = os.path.join(os.getcwd(), 'out')
            if not os.path.isdir(log_dir):
                os.mkdir(log_dir)
            self.write_option(f, "--output="+os.path.join(log_dir, "%j.out"))
            self.write_option(f, "--error="+os.path.join(log_dir, "%j.err"))
        else:
            self.write_option(f, "--output=/dev/null")
            self.write_option(f, "--error=/dev/null")
        self.write_option(f, "--export=ALL")

class SubmitUGE(SubmitPBS):
    """UGE is similar to PBS, but with different headers"""
    
    option_tag = "#$"
    
    def get_cores_for_memory(self, num_cpus_advertised, num_gpus_advertised, mem_advertised):
        """
        Scale number of cores to satisfy memory request.
        
        UGE can assign variable memory per core, so just pass the request straight through.
        """
        return num_cpus_advertised, mem_advertised, mem_advertised
    
    def write_general_header(self, f, mem=3000, walltime_hours=14, disk=1,
                             num_nodes=1, num_cpus=1, num_gpus=0,
                             num_jobs=0):
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
        self.write_option(f, '-S /bin/bash')
        self.write_option(f, '-l h_rss=%dM'%(mem))
        self.write_option(f, '-l tmpdir_size=%dM'%(max((disk, 1000))))
        if num_gpus:
            self.write_option(f, "-l gpu=%d"%num_gpus)
        if num_cpus > 1:
            self.write_option(f, "-pe multicore %d"%num_cpus)
        self.write_option(f, "-l h_rt=%d:00:00" % walltime_hours)
        if self.config["Mode"]["debug"]:
            self.write_option(f, "-o %s/out/$JOB_ID.out"%os.getcwd())
            self.write_option(f, "-e %s/out/$JOB_ID.err"%os.getcwd())
        else:
            self.write_option(f, "-o /dev/null")
            self.write_option(f, "-e /dev/null")
        if num_jobs > 0:
            self.write_option(f, "-t 1-%d" % num_jobs)

class SubmitLSF(SubmitPBS):
    """LSF is similar to PBS, but with different headers"""

    option_tag = "#BSUB"

    def write_general_header(self, f, mem=3000, walltime_hours=14, disk=1,
                             num_nodes=1, num_cpus=1, num_gpus=0,
                             num_jobs=0):
        """
        Writing the header for an LSF submission script.
        Most of the pieces needed to tell LSF what resources
        are being requested.

        Args:
            f: python file object
            mem: requested memory
            walltime_hours: requested wall time
            num_nodes: requested number of nodes
            num_cpus: requested number of cpus
            num_gpus: requested number of gpus
            num_jobs: number of jobs in a job array
        """
        self.write_line(f, "#!/bin/bash")
        if num_gpus > 0:
            self.write_option(f, "-R 'rusage[cuda=%d]'" % num_gpus)
        walltime_line = "-W %d:00" % walltime_hours

        # check for additional parameters in config
        if 'SubmitFile' in self.config:
            submit_conf = self.config['SubmitFile']
            if 'ref_host' in submit_conf:
                # add reference host for walltime if given
                walltime_line+="/%s" % submit_conf['ref_host']

        self.write_option(f, walltime_line)
        # default memory units are kB for LSF
        mem_scale = 1000
        # scale memory to non-default units if parameter exists
        mem_scale*=self.get_resource_limit_scale("mem_scale")
        self.write_option(f, "-M %d" % (mem*mem_scale))
        self.write_option(f, "-n %d" % num_cpus)
        """
        # ignore for now
        # need to make sure to reserve the correct number of nodes
        cpus_tot = num_cpus
        if num_nodes > 1:
            cpus_tot = num_nodes*cpus_per_node
        self.write_option(f, "-n %d -R 'span[ptile=%d]'" %\
                             (cpus_tot, cpus_per_node))
        """
        if num_jobs > 0:
            # job name will be "[index]"
            self.write_option(f, "-J [1-%d]" % num_jobs)

        if ('Mode' in self.config and 'debug' in self.config['Mode']
            and self.config['Mode']['debug']):
            outdir = os.path.join(os.getcwd(), 'out')
            if not os.path.isdir(outdir):
                os.mkdir(outdir)
            # %I is job index (all jobs in an array have same id %J)
            self.write_option(f, "-o %s/%%J_%%I.out" % outdir)
            self.write_option(f, "-e %s/%%J_%%I.err" % outdir)
        else:
            self.write_option(f, "-o /dev/null")
            self.write_option(f, "-e /dev/null")

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
                self.write_line(f, 'SITE="%s"' % self.config['Glidein']['site'])
            if 'cluster' in self.config['Glidein']:
                self.write_line(f, 'CLUSTER="%s"' % self.config['Glidein']['cluster'])
            f.write('env -i CPUS=$CPUS GPUS=$GPUS MEMORY=$MEMORY DISK=$DISK ')
            if 'site' in self.config['Glidein']:
                f.write('SITE=$SITE ')
            if 'cluster' in self.config['Glidein']:
                f.write('CLUSTER=$CLUSTER ')
            if "CustomEnv" in self.config:
                for k, v in self.config["CustomEnv"].items():
                    f.write(k + '=' + v + ' ')
            if 'executable' in self.config['SubmitFile']:
                f.write(str(self.config['SubmitFile']['executable'])+' ')
            f.write(str(self.get_glidein_script()))

            mode = os.fstat(f.fileno()).st_mode
            mode |= 0o111
            os.fchmod(f.fileno(), mode & 0o7777)

    def make_submit_file(self, filename, env_wrapper, state, group_jobs):
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
            glidein_script = self.get_glidein_script()
            if not os.path.isfile(glidein_script):
                raise Exception("no glidein_script provided")
            infiles.append(glidein_script)
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
                mem_safety_margin = 1.1*self.get_resource_limit_scale("mem_safety_scale")
                self.write_line(f, 'request_memory=%d' % int(state["memory"]*mem_safety_margin))
            if state["disk"] != 0:
                self.write_line(f, 'request_disk=%d' % int(state["disk"]*1024*1.1))
            if state["gpus"] != 0:
                self.write_line(f, 'request_gpus=%d' % int(state["gpus"]))

            if "custom_footer" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_footer"])
            if group_jobs:
                self.write_line(f, 'queue %d' % state["count"])
            else:
                self.write_line(f, 'queue')

    def submit(self, state):
        """
        Writing submit file and submitting a HTCondor job

        Args:
            state: what resource requirements a given glidein has
        """
        submit_filename = 'submit.condor'
        if 'filename' in self.config["SubmitFile"]:
            submit_filename = self.config["SubmitFile"]["filename"]
        env_filename = 'env_wrapper.sh'
        if 'env_wrapper_name' in self.config['SubmitFile']:
            env_filename = self.config["SubmitFile"]["env_wrapper_name"]
        
        group_jobs = ("group_jobs" in self.config["Cluster"] and
                      self.config["Cluster"]["group_jobs"] and 
                      "count" in state)
        self.make_env_wrapper(env_filename)
        self.make_submit_file(submit_filename,
                              env_filename,
                              state, 
                              group_jobs)
        num_submits = 1 if group_jobs else state["count"] if "count" in state else 1
        for i in xrange(num_submits):
            cmd = self.config["Cluster"]["submit_command"] + " " + submit_filename
            print(cmd)
            if subprocess.call(cmd, shell=True):
                raise Exception('failed to launch glidein')

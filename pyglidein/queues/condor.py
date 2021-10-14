from __future__ import absolute_import, division, print_function

import logging
import os
import subprocess

from . import BatchQueue


logger = logging.getLogger('condor')

class Condor(BatchQueue):
    """Submit an HTCondor job"""

    def make_env_wrapper_resources(self, f, cluster_config):
        self.write_line(f, 'CPUS=$(grep -e "^Cpus" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}")')
        self.write_line(f, 'MEMORY=$(grep -e "^Memory" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}")')
        self.write_line(f, 'DISK=$(grep -e "^Disk =" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}")')
        if 'resourcename' not in self.config['Glidein']:
            # try glidein-in-glidein detection
            self.write_line(f, 'ResourceName=$(grep -e "^GLIDEIN_ResourceName" $_CONDOR_MACHINE_AD|awk -F "= " "{print \\$2}"|sed "s/\\"//g")')

    def make_submit_file(self, filename, env_wrapper, count, cluster_config):
        """
        Creating HTCondor submit file

        Args:
            filename (str): name of HTCondor submit file
            env_wrapper (str): name of wrapper script
            count (int): number of jobs to submit
            cluster_config (dict): config for this partition
        """
        with open(filename, 'w') as f:
            if "custom_header" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_header"])

            if 'Mode' in self.config and self.config["Mode"].get("debug", False):
                outdir = os.path.join(os.getcwd(), 'out')
                if not os.path.isdir(outdir):
                    os.mkdir(outdir)
                self.write_line(f, "output = %s/$(Cluster).out"%outdir)
                self.write_line(f, "error = %s/$(Cluster).out"%outdir)
            else:
                self.write_line(f, "output = /dev/null")
                self.write_line(f, "error = /dev/null")
            self.write_line(f, "log = " + self.config['SubmitFile'].get('log', 'log'))
            self.write_line(f, "notification = never")
            self.write_line(f, "should_transfer_files = YES")
            self.write_line(f, "when_to_transfer_output = ON_EXIT")
            self.write_line(f, "want_graceful_removal = True")
            self.write_line(f, "executable = %s" % env_wrapper)
            self.write_line(f, "+TransferOutput = \"\"")

            # get input files
            infiles = []
            glidein_script = self.get_glidein_script()
            if not os.path.isfile(glidein_script):
                raise Exception("no glidein_script provided")
            infiles.append(glidein_script)
            self.write_line(f, "transfer_input_files = %s"%(','.join(infiles)))

            if "custom_middle" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_middle"])

            cpus = int(cluster_config['cpus'])
            mem = int(float(cluster_config['memory'])*1000)
            disk = int(float(cluster_config['disk'])*1000*1000)
            gpus = int(cluster_config['gpus'])
            time = float(cluster_config['time'])

            self.write_line(f, 'request_cpus = %d' % cpus)
            if gpus:
                self.write_line(f, 'request_gpus = %d' % gpus)
            self.write_line(f, 'request_memory = %d' % mem)
            self.write_line(f, 'request_disk = %d' % disk)
            self.write_line(f, '+TimeHours = %f' % time)

            if "custom_footer" in self.config["SubmitFile"]:
                self.write_line(f, self.config["SubmitFile"]["custom_footer"])
            self.write_line(f, 'queue %d' % count)

    def submit(self, state):
        """
        Writing submit file and submitting a HTCondor job

        Args:
            state (dict): number of jobs to submit for each partition
        """
        for p in state:
            if p not in self._partitions:
                raise Exception('bad partition name '+p)

            submit_filename = 'submit.condor'
            if 'filename' in self.config["SubmitFile"]:
                submit_filename = self.config["SubmitFile"]["filename"]
            env_filename = 'env_wrapper.sh'
            if 'env_wrapper_name' in self.config['SubmitFile']:
                env_filename = self.config["SubmitFile"]["env_wrapper_name"]

            cluster_config = self.config[p]
            num_submits = state[p]
            self.make_env_wrapper(env_filename, cluster_config)
            self.make_submit_file(submit_filename,
                                  env_filename,
                                  num_submits,
                                  cluster_config)
            cmd = ['condor_submit', submit_filename]
            subprocess.check_call(cmd)

    def status(self):
        """
        Get the idle/running count for all partitions.
        """
        if self.all_partitions_running_idle_cmd():
            return super().status()

        cmd = ['condor_q', self._user, '-af', 'JobStatus', 'RequestCPUs',
               'RequestGPUs', 'RequestMemory', 'RequestDisk', 'TimeHours']
        out = subprocess.check_output(cmd)
        out_parsed = []
        for line in out.split('\n'):
            line = line.strip()
            if line:
                try:
                    status, cpus, gpus, memory, disk, time = line.split()
                except ValueError:
                    logger.debug(f'bad line from condor_q: {line}')
                    continue
                if status == '1':
                    status = 'idle'
                elif status == '2':
                    status = 'running'
                else:
                    logger.debug(f'bad status from condor_q: {status}')
                    continue # ignore unknown jobs
                cpus = int(cpus)
                if gpus == 'undefined':
                    gpus = 0
                else:
                    gpus = int(gpus)
                memory = float(memory)/1000
                disk = float(disk)/1000/1000
                time = float(time)
                out_parsed.append((status, cpus, gpus, memory, disk, time))

        ret = {}
        for line in out_parsed:
            status, cpus, gpus, memory, disk, time = line
            for p in self._partitions:
                cfg = self.config[p]
                if (cfg['cpus'] == cpus
                    and cfg['gpus'] == gpus
                    and float(cfg['memory']) == memory
                    and float(cfg['disk']) == disk
                    and cfg['time'] == time):
                    if p not in ret:
                        ret[p] = {'idle': 0, 'running': 0}
                    ret[p][status] += 1
                    break
            else:
                logger.info(f'skipped line in status: {line}')

        return ret

import getpass
import logging
import subprocess
import os

logger = logging.getLogger('BatchQueue')

class BatchQueue:
    """
    Base class for the queue classes
    Mostly to provide future expansion for common functions
    """
    def __init__(self, config, secrets):
        """
        Initialize

        Args:
            config: cluster config dict for cluster
            secrets: cluster secrets dict for cluster
        """
        self.config = config
        self.secrets = secrets

    ### Override these methods

    def status(self):
        """
        Get the queue status, returning running and idle jobs for each partition.

        Uses "running_cmd" and "idle_cmd", which are expected to print an
        integer to stdout.

        Returns:
            dict: "running" and "idle" count
        """
        if not self.all_partitions_running_idle_cmd():
            raise Exception('status() requires running_cmd and idle_cmd in each partition')

        ret = {}
        for p in self._partitions:
            logger.debug(f'getting status for partition {p}')
            cfg = self.config[p]
            try:
                out = subprocess.check_output(cfg['running_cmd'], shell=True)
                out2 = subprocess.check_output(cfg['idle_cmd'], shell=True)
                ret[p] = {
                    'running': int(out.strip()),
                    'idle': int(out2.strip()),
                }
            except Exception:
                logger.warning('error getting status for partition %s', p)
                raise
        return ret

    def submit(self, state):
        raise NotImplementedError()

    def cleanup(self):
        pass

    ### Common methods below

    @property
    def _partitions(self):
        """List partition names"""
        return self.config['Cluster'].get('partitions', ['Cluster'])

    @property
    def _user(self):
        return getpass.getuser()

    def all_partitions_running_idle_cmd(self):
        return all('running_cmd' in self.config[p] and 'idle_cmd' in self.config[p] for p in self._partitions)

    @staticmethod
    def write_line(f, line):
        """
        Wrapper function so we don't have to write `\n` a million times

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
        if 'glidein_script' in self.config['Glidein']:
            return self.config['Glidein']['glidein_script']

        # If the user hasn't set ['Glidein']['glidein_script'] assume they want to use the
        # glidein_scripts provided by the python package.
        package_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        return os.path.join(package_dir, 'glidein_start.sh')

    def make_env_wrapper_customize(self, f, cluster_config):
        """Any custom env for a queue, such as reading resources from the queue."""
        self.write_line(f, 'CPUS=%s' % cluster_config['cpus'])
        self.write_line(f, 'MEMORY=%s' % cluster_config['memory'])
        self.write_line(f, 'DISK=%s' % cluster_config['disk'])

    def make_env_wrapper(self, env_wrapper, cluster_config):
        """
        Creating wrapper execute script for
        HTCondor submit file

        Args:
            env_wrapper: name of wrapper script
            cluster_config: partition config
        """
        with open(env_wrapper, 'w') as f:
            self.write_line(f, '#!/bin/sh')
            self.write_line(f, 'SITE="%s"' % self.config['Glidein'].get('site', 'Test'))
            self.write_line(f, 'ResourceName="%s"' % self.config['Glidein'].get('resourcename', 'Test'))
            self.make_env_wrapper_customize(f, cluster_config)

            f.write('exec env -i CPUS=$CPUS MEMORY=$MEMORY DISK=$DISK '
                    'PRESIGNED_PUT_URL=$PRESIGNED_PUT_URL PRESIGNED_GET_URL=$PRESIGNED_GET_URL '
                    'GLIDEIN_Site=$SITE GLIDEIN_ResourceName=$ResourceName '
                    'CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES ')

            f.write('ACCEPT_JOBS_FOR_HOURS=%s ' % cluster_config["time"])
            if "CustomEnv" in self.config:
                for k, v in self.config["CustomEnv"].items():
                    f.write(k + '=' + v + ' ')
            f.write(str(os.path.basename(self.get_glidein_script())))

        mode = os.stat(env_wrapper).st_mode
        mode |= 0o111
        os.chmod(env_wrapper, mode & 0o7777)

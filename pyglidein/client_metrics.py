import logging
import os
import pwd
import shlex

from datetime import datetime, timedelta
from subprocess import check_output, STDOUT
from pyglidein.client_util import Client


class ClientMetrics(object):
    """
    Base class for the client metrics classes.  Provides a framework for collecting client metrics
    and sending them to an endpoint
    """

    def __init__(self, config, secrets):

        if config.get('Cluster', {}).get('user', None) is not None:
            self.user = config['Cluster']['user']
        elif os.environ.get('USER', None) is not None:
            self.user = os.environ['USER']
        else:
            self.user = pwd.getpwuid(os.getuid()).pw_name

        self.address = config['Glidein']['address']

        self.config = config
        self.secrets = secrets
        self.logger = logging.getLogger('client')

    def send(self, metrics_bundle):
        """
        Sending metrics information back
        """
        c = Client(address=self.address)
        try:
            return c.request('monitoring', metrics_bundle.get_bundle())
        except Exception:
            self.logger.warn('error getting state', exc_info=True)


class ClientMetricsCondor(ClientMetrics):
    """
    Collect client metrics from a Condor cluster
    """

    def get_mma_idle_time(self, partition='Cluster'):
        import classad
        import htcondor
        
        schedd = htcondor.Schedd()
        now = datetime.now()
        job_count = 0
        total = timedelta(0)
        min_delta = timedelta.max
        max_delta = timedelta(0)
        metrics = {
            'avg_idle_time': {},
            'min_idle_time': {},
            'max_idle_time': {}
        }

        requirements = 'Owner == "{}" && '.format(self.user)
        requirements += 'JobStatus == 1'
        projection = ['QDate']
        for job in schedd.xquery(requirements=requirements, projection=projection):
            delta = now - datetime.fromtimestamp(job['QDate'])
            if delta < min_delta:
                min_delta = delta
            if delta > max_delta:
                max_delta = delta
            total += delta
            job_count += 1

        # Updating Metrics
        if job_count > 0:
            metrics['avg_idle_time'][partition] = int(total.total_seconds() / job_count)
        else:
            metrics['avg_idle_time'][partition] = 0
        metrics['min_idle_time'][partition] = int(min_delta.total_seconds())
        metrics['max_idle_time'][partition] = int(max_delta.total_seconds())

        self.logger.debug('avg_idle_time for ' +
                          '{}: {}s.'.format(partition, metrics['avg_idle_time'][partition]))
        self.logger.debug('min_idle_time for ' +
                          '{}: {}s.'.format(partition, metrics['min_idle_time'][partition]))
        self.logger.debug('max_idle_time for ' +
                          '{}: {}s.'.format(partition, metrics['max_idle_time'][partition]))

        return metrics


class ClientMetricsSlurm(ClientMetrics):
    """
    Collect client metrics from a Slurm cluster
    """

    def get_mma_idle_time(self, partition='Cluster'):
        DEFAULT_MMA_CMD = 'squeue -u {} -t PENDING -o "%V" -h'.format(self.user)

        now = datetime.now()
        job_count = 0
        total = timedelta(0)
        min_delta = timedelta.max
        max_delta = timedelta(0)
        metrics = {
            'avg_idle_time': {},
            'min_idle_time': {},
            'max_idle_time': {}
        }

        cmd = DEFAULT_MMA_CMD
        if self.config.get(partition, {}).get('mma_cmd', False):
            cmd = self.config[partition]['mma_cmd']
        cmd = os.path.expandvars(cmd)
        cmd = shlex.split(cmd)
        output = check_output(cmd, shell=False, env=os.environ, stderr=STDOUT)
        for line in output.split('\n'):
            if line != '':
                qtime = datetime.strptime(line, '%Y-%m-%dT%H:%M:%S')
                delta = now - qtime
                if delta < min_delta:
                    min_delta = delta
                if delta > max_delta:
                    max_delta = delta
                total += delta
                job_count += 1

        # Updating Metrics
        if job_count > 0:
            metrics['avg_idle_time'][partition] = int(total.total_seconds() / job_count)
            metrics['min_idle_time'][partition] = int(min_delta.total_seconds())
            metrics['max_idle_time'][partition] = int(max_delta.total_seconds())
        else:
            metrics['avg_idle_time'][partition] = 0
            metrics['min_idle_time'][partition] = 0
            metrics['max_idle_time'][partition] = 0

        self.logger.debug('avg_idle_time for ' +
                          '{}: {}s.'.format(partition, metrics['avg_idle_time'][partition]))
        self.logger.debug('min_idle_time for ' +
                          '{}: {}s.'.format(partition, metrics['min_idle_time'][partition]))
        self.logger.debug('max_idle_time for ' +
                          '{}: {}s.'.format(partition, metrics['max_idle_time'][partition]))

        return metrics


class ClientMetricsPBS(ClientMetrics):
    """
    Collect client metrics from a PBS cluster
    """

    def get_mma_idle_time(self, partition='Cluster'):
        DEFAULT_MMA_CMD = 'qstat -u {} -f'.format(self.user)

        now = datetime.now()
        job_count = 0
        total = timedelta(0)
        min_delta = timedelta.max
        max_delta = timedelta(0)
        metrics = {
            'avg_idle_time': {},
            'min_idle_time': {},
            'max_idle_time': {}
        }

        cmd = DEFAULT_MMA_CMD
        if self.config.get(partition, {}).get('mma_cmd', False):
            cmd = self.config[partition]['mma_cmd']
        cmd = os.path.expandvars(cmd)
        cmd = shlex.split(cmd)
        output = check_output(cmd, shell=False, env=os.environ, stderr=STDOUT)
        idle = False
        for line in output.split('\n'):
            if 'job_state = Q' in line:
                idle = True
            elif 'qtime' in line and idle:
                idle = False
                qtime = datetime.strptime(line.split('=')[1].lstrip(), '%a %b %d %H:%M:%S %Y')
                delta = now - qtime
                if delta < min_delta:
                    min_delta = delta
                if delta > max_delta:
                    max_delta = delta
                total += delta
                job_count += 1

        # Updating Metrics
        if job_count > 0:
            metrics['avg_idle_time'][partition] = int(total.total_seconds() / job_count)
        else:
            metrics['avg_idle_time'][partition] = 0
        metrics['min_idle_time'][partition] = int(min_delta.total_seconds())
        metrics['max_idle_time'][partition] = int(max_delta.total_seconds())

        self.logger.debug('avg_idle_time for ' +
                          '{}: {}s.'.format(partition, metrics['avg_idle_time'][partition]))
        self.logger.debug('min_idle_time for ' +
                          '{}: {}s.'.format(partition, metrics['min_idle_time'][partition]))
        self.logger.debug('max_idle_time for ' +
                          '{}: {}s.'.format(partition, metrics['max_idle_time'][partition]))

        return metrics


class ClientMetricsBundle(object):

    whitelist = {
        'glideins_launched': True,
        'glideins_running': True,
        'glideins_idle': True,
        'avg_idle_time': True,
        'min_idle_time': True,
        'max_idle_time': True
    }

    def __init__(self, uuid, metrics={}, timestamp=None):

        self.metrics = {
            'avg_idle_time': {
                'Cluster': 0
            },
            'min_idle_time': {
                'Cluster': 0
            },
            'max_idle_time': {
                'Cluster': 0
            },
            'glideins_idle': {
                'Cluster': 0
            },
            'glideins_launched': {
                'Cluster': 0
            },
            'glideins_running': {
                'Cluster': 0
            }
        }
        if timestamp is not None:
            self.timestamp = timestamp
        else:
            self.timestamp = int(datetime.utcnow().strftime('%s'))
        self.uuid = uuid

        # Pruning non whitelisted metrics and converting to ints
        self.update_metrics(metrics)

    def get_metrics(self):
        return self.metrics

    def get_timestamp(self):
        return self.timestamp

    def get_uuid(self):
        return self.uuid

    def get_bundle(self):
        bundle = {
            'uuid': self.uuid,
            'timestamp': self.timestamp,
            'metrics': self.metrics
        }
        return bundle

    def get_v1_bundle(self):
        bundle = {
            'timestamp': self.timestamp
        }
        for m in self.metrics:
            bundle[m] = sum(self.metrics[m].values())
        return bundle

    def update_metric(self, metric_name, partition, value):
        if ClientMetricsBundle.whitelist.get(metric_name, False):
            try:
                self.metrics[metric_name][partition] = int(value)
                return True
            except:
                return False

    def update_metrics(self, metrics):
        for k in metrics:
            if ClientMetricsBundle.whitelist.get(k, False):
                # Handling metrics from old clients
                if type(metrics[k]) is not dict:
                    try:
                        self.metrics[k]['Cluster'] = int(metrics[k])
                    except:
                        self.metrics[k]['Cluster'] = 0
                else:
                    for partition in metrics[k]:
                        try:
                            self.metrics[k][partition] = int(metrics[k][partition])
                        except:
                            self.metrics[k][partition] = 0

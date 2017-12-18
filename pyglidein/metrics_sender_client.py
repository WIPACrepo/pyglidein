import logging
import pickle
import socket
import struct
import sys


class MetricsSenderClient(object):

    client_metrics_namespace = {
        'glideins_launched': 'glideins.launched',
        'glideins_running': 'glideins.running',
        'glideins_idle': 'glideins.idle',
        'avg_idle_time': 'glideins.avg_idle_time',
        'min_idle_time': 'glideins.min_idle_time',
        'max_idle_time': 'glideins.max_idle_time'
    }

    def __init__(self, config):

        self.logger = logging.getLogger('server')
        self.graphite_server = config.get('graphite_server', None)
        if self.graphite_server is None:
            self.logger.error('graphite_server not defined in configuration.')
            sys.exit(1)
        self.graphite_port = config.get('graphite_port', 2004)
        self.namespace = config.get('namespace', 'pyglidein')

    def send(self, metrics_bundle):

            payload = []
            uuid = metrics_bundle.get_uuid()
            timestamp = metrics_bundle.get_timestamp()
            metrics = metrics_bundle.get_metrics()
            for metric in metrics:
                for partition in metrics[metric]:
                    path = str('.'.join([self.namespace, uuid, partition,
                                        MetricsSenderClient.client_metrics_namespace[metric]]))
                    payload.append((path, (timestamp, metrics[metric][partition])))
            self.logger.debug(payload)
            payload = pickle.dumps(payload, protocol=2)
            header = struct.pack("!L", len(payload))
            message = header + payload

            sock = socket.socket()
            sock.connect((self.graphite_server, self.graphite_port))
            sock.sendall(message)
            sock.close()

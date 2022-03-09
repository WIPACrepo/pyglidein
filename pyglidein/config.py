import ast
try:
    from configparser import ConfigParser
except ImportError:
    from ConfigParser import SafeConfigParser as ConfigParser
import logging
import os


logger = logging.getLogger('config')

class Config(dict):
    def __init__(self, path, default=None):
        self.path = path
        if not default:
            default = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                   'etc/client_defaults.cfg')

        # read defaults
        tmp = ConfigParser()
        tmp.optionxform = str
        tmp.read(default)
        self._config_options_dict(tmp)

        # read file
        tmp = ConfigParser()
        tmp.optionxform = str
        tmp.read(path)
        self._config_options_dict(tmp)

        # cluster partitions
        self._populate_partitions()

    def _config_options_dict(self, config):
        """
        Parsing config file
        Args:
            config: Python config parser object
        """
        for section in config.sections():
            if section not in self:
                self[section] = {}
            for option in config.options(section):
                val = config.get(section, option)
                try:
                    val = ast.literal_eval(val)
                except Exception as e:
                    pass
                self[section][option] = val

    def _populate_partitions(self):
        cluster_config = self.get('Cluster', dict())
        if 'partitions' in cluster_config:
            cluster_config['partitions'] = [k.strip() for k in cluster_config['partitions'].split(',')]
            for k in cluster_config['partitions']:
                if not k in self:
                    continue
                config = dict(cluster_config)
                config.update(self[k])
                self[k] = config

from ConfigParser import SafeConfigParser

import os
import ast

class Config(dict):
    def __init__(self, path, default='etc/client_defaults.cfg'):
        self.path = path

        # read defaults
        tmp = SafeConfigParser()
        tmp.read(default)
        self._config_options_dict(tmp)

        # read file
        tmp = SafeConfigParser()
        tmp.read(path)
        self._config_options_dict(tmp)

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
                except Exception:
                    pass
                self[section][option] = val

#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

from argparse import ArgumentParser
import importlib
import logging
import os
import stat
import sys

from pyglidein.config import Config
from pyglidein.server import Server


logger = logging.getLogger('client')

def run(config_dict, secrets_dict):
    # Importing the correct class to handle the submit
    sched_type = config_dict['Cluster']['scheduler'].lower()
    try:
        mod = importlib.import_module('pyglidein.queues.'+sched_type)
        scheduler = getattr(mod, sched_type.capitalize())(config_dict, secrets_dict)
    except (ImportError, KeyError):
        raise Exception('scheduler not supported')

    server = Server(config_dict, secrets_dict)

    while True:
        st = scheduler.status()
        queue = server.get(st)
        if queue:
            scheduler.submit(queue)

        if int(config_dict['Glidein'].get('delay', '-1')) < 1:
            break
        time.sleep(config_dict['Glidein']['delay'])

    scheduler.cleanup()

def main():
    parser = ArgumentParser()
    parser.add_argument('--config', type='string', default='cluster.config',
                        help="config file for cluster")
    parser.add_argument('--secrets', type='string', default='.pyglidein_secrets',
                        help="secrets file for cluster")
    args = parser.parse_args()
    args = vars(args)

    config_dict = Config(args['config'])

    if config_dict['Mode']['debug']:
        logging.basicConfig(level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s')
    else:
        logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')

    # Loading secrets.  Fail if permissions wrong.
    if os.path.isfile(args['secrets']):
        if os.stat(args['secrets']).st_mode & (stat.S_IXGRP | stat.S_IRWXO):
            logger.error('Set Permissions on {} to 600'.format(args['secrets']))
            sys.exit(1)
        secrets_dict = Config(args['secrets'])
    else:
        logger.error('Error Accessing Secrets File: {}.  '.format(args['secrets']) +
                     'Did you set the --secrets flag?')
        sys.exit(1)

    run(config_dict, secrets_dict)

if __name__ == '__main__':
    main()

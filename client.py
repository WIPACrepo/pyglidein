#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

import os
import time
import subprocess
import logging
from optparse import OptionParser
import ConfigParser

from util import json_decode, config_options_dict
from client_util import get_state
import submit

logger = logging.getLogger('client')


def get_ssh_state():
    try:
        filename = os.path.expanduser('~/glidein_state')
        return json_decode(open(filename).read())
    except Exception:
        logger.warn('error getting ssh state', exc_info=True)

def launch_glidein(cmd, params=[]):
    for p in params:
        cmd += ' --'+p+' '+str(params[p])
    print(cmd)
    if subprocess.call(cmd, shell=True):
        raise Exception('failed to launch glidein')

def get_running(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    return int(p.communicate()[0].strip())

def main():
    parser = OptionParser()
    parser.add_option('--config', type='string', default='cluster.config',
                      help="config file for cluster")
    (options, args) = parser.parse_args()
    config = ConfigParser.ConfigParser()
    config.read(options.config)
    config_dict = config_options_dict(config)
    config_glidein = config_dict['Glidein']
    config_cluster = config_dict['Cluster']

    # Importing the correct class to handle the submit
    if config_cluster["scheduler"] == "htcondor":
        scheduler = submit.SubmitCondor(config_dict)
    elif config_cluster["scheduler"] == "pbs":
        scheduler = submit.SubmitPBS(config_dict)
    elif config_cluster["scheduler"] == "slurm":
        scheduler = submit.SubmitSLURM(config_dict)
    else:
        raise Exception('scheduler not supported')

    # if "glidein_cmd" not in config_dict["Glidein"]:
    #     raise Exception('no glidein_cmd')
    if "running_cmd" not in config_dict["Cluster"]:
        raise Exception('no running_cmd')

    if ('Mode' in config_dict and 'debug' in config_dict['Mode'] and
        config_dict['Mode']['debug']):
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    while True:
        if 'ssh_state' in config_glidein and config_glidein['ssh_state']:
            state = get_ssh_state()
        else:
            state = get_state(config_glidein['address'])
        if state:
            try:
                glideins_running = get_running(config_cluster["running_cmd"])
            except Exception:
                logger.warn('error getting running job count', exc_info=True)
                continue
            i = 0
            for s in state:
                # Skipping CPU jobs for gpu only clusters
                if ('gpu_only' in config_cluster and config_cluster['gpu_only']
                    and s["gpus"] == 0):
                    continue
                # skipping GPU jobs for cpu only clusters
                if ('cpu_only' in config_cluster and config_cluster['cpu_only']
                    and s["gpus"] != 0):
                    continue
                if (i >= config_cluster["limit_per_submit"]
                    or i + glideins_running >= config_cluster["max_total_jobs"]):
                    logger.info('reached limit')
                    break
                scheduler.submit(s)
                i += 1
            logger.info('launched %d glideins', i)
        else:
            logger.info('no state, nothing to do')

        if 'delay' not in config_glidein or int(config_glidein['delay']) < 1:
            break
        time.sleep(config_glidein['delay'])


if __name__ == '__main__':
    main()

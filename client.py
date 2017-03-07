#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

import os
import time
import subprocess
import logging
import socket
import getpass
from optparse import OptionParser
import glob
import shutil

from util import json_decode
from client_util import get_state, monitoring, config_options_dict
import submit

from config import Config

logger = logging.getLogger('client')


def get_ssh_state():
    """Getting the state of the remote queue from a text file"""
    try:
        filename = os.path.expanduser('~/glidein_state')
        return json_decode(open(filename).read())
    except Exception:
        logger.warn('error getting ssh state', exc_info=True)

def get_running(cmd):
    """Determine how many jobs are running in the queue"""
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    return int(p.communicate()[0].strip())

def sort_states(state, columns, reverse=True):
    """
    Sort the states according to the list given by prioritize_jobs.
    
    prioritize_jobs (or columns in this case) is list of according to 
    which state should be prioritized for job submission. The position 
    in the list indicates the prioritization. columns = ["memory", "disk"] 
    with reverse=True means jobs with high memory will be submitted before
    jobs with lower memory requirements, followed by jobs with high disk vs. 
    low disk requirement. Jobs with high memory and disk requirements 
    will be submitted first then jobs with high memory and medium disk 
    requirements, and so on and so forth. 

    Args:
        state: List of states
        columns: List of keys in the dict by which dict is sorted
        reverse: Reverse the sorting or not. True = Bigger first,
                 False = smaller first
    """
    key_cache = {}
    col_cache = dict([(c[1:],-1) if c[0] == '-' else (c,1) for c in columns])
    def comp_key(key):
        if key in key_cache:
            return key_cache[key]
        if key in col_cache:
            ret = len(columns)-columns.index(key if col_cache[key] == 1 else '-'+key)
        else:
            ret = 0
        key_cache[key] = ret
        return ret
    def compare(row):
        ret = []
        for k in sorted(row, key=comp_key, reverse=True):
            v = row[k]
            if k in col_cache:
                v *= col_cache[k]
            ret.append(v)
        return ret
    return sorted(state, key=compare, reverse=reverse)

def main():
    parser = OptionParser()
    parser.add_option('--config', type='string', default='cluster.config',
                      help="config file for cluster")
    parser.add_option('--uuid', type='string',
                      default=getpass.getuser()+'@'+socket.gethostname(),
                      help="Unique id for this client")
    (options, args) = parser.parse_args()

    config_dict = Config(options.config)
    config_glidein = config_dict['Glidein']
    config_cluster = config_dict['Cluster']

    # Importing the correct class to handle the submit
    sched_type = config_cluster["scheduler"].lower()
    if sched_type == "htcondor":
        scheduler = submit.SubmitCondor(config_dict)
    elif sched_type == "pbs":
        scheduler = submit.SubmitPBS(config_dict)
    elif sched_type == "slurm":
        scheduler = submit.SubmitSLURM(config_dict)
    elif sched_type == "uge":
        scheduler = submit.SubmitUGE(config_dict)
    elif sched_type == "lsf":
        scheduler = submit.SubmitLSF(config_dict)
    else:
        raise Exception('scheduler not supported')

    # if "glidein_cmd" not in config_dict["Glidein"]:
    #     raise Exception('no glidein_cmd')

    if ('Mode' in config_dict and 'debug' in config_dict['Mode'] and
        config_dict['Mode']['debug']):
        logging.basicConfig(level=logging.DEBUG,format='%(asctime)s %(levelname)s %(message)s')
    else:
        logging.basicConfig(level=logging.INFO,format='%(asctime)s %(levelname)s %(message)s')

    while True:
        if 'ssh_state' in config_glidein and config_glidein['ssh_state']:
            state = get_ssh_state()
        else:
            state = get_state(config_glidein['address'])
        if 'uuid' in config_glidein:
            options.uuid = config_glidein['uuid']
        info = {'uuid': options.uuid,
                'glideins_running': dict(),
                'glideins_launched': dict(),
               }
        if state:
            for partition in config_dict['Cluster'].get('partitions', ['Cluster']):
                config_cluster = config_dict[partition]
                if "running_cmd" not in config_cluster:
                    raise Exception('Section [%s] has no running_cmd' % partition)
                idle = 0
                try:
                    info['glideins_running'][partition] = get_running(config_cluster["running_cmd"])
                    if "idle_cmd" in config_cluster:
                        idle = get_running(config_cluster["idle_cmd"])
                except Exception:
                    logger.warn('error getting running job count', exc_info=True)
                    continue
                info['glideins_launched'][partition] = 0
                limit = min(config_cluster["limit_per_submit"], 
                            config_cluster["max_total_jobs"] - info['glideins_running'][partition],
                            max(config_cluster.get("max_idle_jobs", 1000) - idle, 0))
                # Prioitize job submission. By default, prioritize submission of gpu and high memory jobs. 
                state = sort_states(state, config_cluster["prioritize_jobs"])
                for s in state:
                    if sched_type == "pbs":
                        s["memory"] = s["memory"]*1024/1000 
                    if limit <= 0:
                        logger.info('reached limit')
                        break
                    # Skipping CPU jobs for gpu only clusters
                    if ('gpu_only' in config_cluster and config_cluster['gpu_only']
                        and s["gpus"] == 0):
                        continue
                    # skipping GPU jobs for cpu only clusters
                    if ('cpu_only' in config_cluster and config_cluster['cpu_only']
                        and s["gpus"] != 0):
                        continue
                    # skipping jobs over cluster resource limits
                    if config_cluster['whole_node']:
                        prefix = 'whole_node_%s'
                    else:
                        prefix = 'max_%s_per_job'
                    for resource in ('cpus','gpus','memory','disk'):
                        cfg_name = prefix%resource
                        if (cfg_name in config_cluster
                            and s[resource] > config_cluster[cfg_name]):
                            break
                        cfg_name = 'min_%s_per_job'%resource
                        if (cfg_name in config_cluster
                            and s[resource] < config_cluster[cfg_name]):
                            break
                    else:
                        if "count" in s and s["count"] > limit:
                            s["count"] = limit
                        scheduler.submit(s, partition)
                        num = 1 if "count" not in s else s["count"]
                        limit -= num
                        info['glideins_launched'][partition] += num
                logger.info('launched %d glideins on %s', info['glideins_launched'][partition], partition)
        else:
            logger.info('no state, nothing to do')

        # send monitoring info to server
        for k in info.keys():
            if isinstance(info[k], dict):
                info[k] = sum(info[k].values())
        monitoring(config_glidein['address'], info)

        if 'delay' not in config_glidein or int(config_glidein['delay']) < 1:
            break
        time.sleep(config_glidein['delay'])
    for partition in config_dict['Cluster'].get('partitions', ['Cluster']):
        config_cluster = config_dict[partition]
        if "cleanup" in config_cluster and config_cluster["cleanup"]:
            scheduler.cleanup(config_cluster["running_cmd"], config_cluster["dir_cleanup"])


if __name__ == '__main__':
    main()

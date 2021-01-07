#!/usr/bin/env python

import os
from optparse import OptionParser
from subprocess import check_output, STDOUT
import json

OUTPUT_FILE = 'benchmark.json'

CLASSAD_MAP = {'I3CLSimModule_makeCLSimHits_makePhotons_clsim_AverageDeviceTimePerPhoton':
               'PYGLIDEIN_METRIC_TIME_PER_PHOTON'}


def main():

    usage = "usage: %prog [options]"
    parser = OptionParser(usage)
    parser.add_option('-n', type='str', default='100',
                      help="Number of simulations to run")
    (options, args) = parser.parse_args()

    try:
        env = os.environ
        gpus = env.get('GPUS', '0')
        if gpus == '0':
            print 'PYGLIDEIN_RESOURCE_GPU=False'
            print '- update:true'
        else:
            gpu = gpus.split(',')[0][4]
            env['CUDA_VISIBLE_DEVICES'] = gpu
            cmd = []
            cmd.append(os.path.join('/cvmfs/icecube.opensciencegrid.org/py3-v4.1.1',
                                    os.environ['OS_ARCH'],
                                    'metaprojects/combo/V01-01-00/env-shell.sh'))
            cmd.append(os.path.join('/cvmfs/icecube.opensciencegrid.org/py3-v4.1.1',
                                    os.environ['OS_ARCH'],
                                    'metaprojects/combo/V01-01-00/clsim/resources',
                                    'scripts/benchmark.py'))
            cmd.extend(['-n', options.n, '-x', OUTPUT_FILE])

            check_output(cmd, shell=False, env=env, stderr=STDOUT)

            with open(OUTPUT_FILE) as f:
                data = json.load(f)

            for el in data:
                if el in CLASSAD_MAP:
                        print '{}={}'.format(CLASSAD_MAP[el], data[el])

            print 'PYGLIDEIN_RESOURCE_GPU=True'
            print '- update:true'
    except:
        print 'PYGLIDEIN_RESOURCE_GPU=False'
        print '- update:true'


if __name__ == '__main__':
    main()

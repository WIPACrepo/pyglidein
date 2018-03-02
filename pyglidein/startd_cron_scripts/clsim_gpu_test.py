#!/usr/bin/env python

import os
from optparse import OptionParser
from subprocess import check_output, STDOUT
import xml.etree.ElementTree as ET

OUTPUT_FILE = 'benchmark.xml'

CLASSAD_MAP = {'I3CLSimModule_makeCLSimHits_makePhotons_clsim_AverageDeviceTimePerPhoton':
               'PYGLIDEIN_METRIC_TIME_PER_PHOTON'}


def main():

    usage = "usage: %prog [options]"
    parser = OptionParser(usage)
    parser.add_option('-n', type='str', default=1,
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
            cmd.append(os.path.join('/cvmfs/icecube.opensciencegrid.org/py2-v2',
                                    os.environ['OS_ARCH'],
                                    'metaprojects/simulation/V05-00-07/env-shell.sh'))
            cmd.append(os.path.join('/cvmfs/icecube.opensciencegrid.org/py2-v2',
                                    os.environ['OS_ARCH'],
                                    'metaprojects/simulation/V05-00-07/clsim/resources',
                                    'scripts/benchmark.py'))
            cmd.extend(['-n', options.n])

            check_output(cmd, shell=False, env=env, stderr=STDOUT)

            tree = ET.parse(OUTPUT_FILE)
            root = tree.getroot()
            for child in root[0][1]:
                if child.tag == 'item' and child[0].text in CLASSAD_MAP:
                        print '{}={}'.format(CLASSAD_MAP[child[0].text], child[1].text)

            print 'PYGLIDEIN_RESOURCE_GPU=True'
            print '- update:true'
    except:
        print 'PYGLIDEIN_RESOURCE_GPU=False'
        print '- update:true'


if __name__ == '__main__':
    main()

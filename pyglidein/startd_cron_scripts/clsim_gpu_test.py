#!/usr/bin/env python

import base64
import os
from optparse import OptionParser
from subprocess import CalledProcessError, check_output, STDOUT
import sys
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
        cmd = []
        cmd.append(os.path.join('/cvmfs/icecube.opensciencegrid.org/py2-v2',
                                os.environ['OS_ARCH'],
                                'metaprojects/simulation/V05-00-07/env-shell.sh'))
        cmd.append(os.path.join('/cvmfs/icecube.opensciencegrid.org/py2-v2',
                                os.environ['OS_ARCH'],
                                'metaprojects/simulation/V05-00-07/clsim/resources',
                                'scripts/benchmark.py'))
        cmd.extend(['-n', options.n])
        try:
            check_output(cmd, shell=False, env=os.environ, stderr=STDOUT)
        except CalledProcessError as e:
            print 'PYGLIDEIN_RESOURCE_GPU="{}"'.format(base64.b64encode(e.output))
            print '- update:true'
            sys.exit(0)
        
        tree = ET.parse(OUTPUT_FILE)
        root = tree.getroot()
        for child in root[0][1]:
            if child.tag == 'item' and child[0].text in CLASSAD_MAP:
                    print '{}={}'.format(CLASSAD_MAP[child[0].text], child[1].text)

        print 'PYGLIDEIN_RESOURCE_GPU=True'
        print '- update:true'
    except SystemExit:
        print 'SystemExit'
    except:
        print 'PYGLIDEIN_RESOURCE_GPU=False'
        print '- update:true'


if __name__ == '__main__':
    main()

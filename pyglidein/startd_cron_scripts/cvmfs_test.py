#!/usr/bin/env python

import os
from optparse import OptionParser
from subprocess import Popen, PIPE


def main():

    usage = "usage: %prog [options] FILE MD5SUM"
    parser = OptionParser(usage)

    (options, args) = parser.parse_args()

    if len(args) != 2:
        raise Exception('Number Of Args != 2')
    cvmfs_test_file = args[0]
    cvmfs_md5sum = args[1]

    try:
        if os.path.isfile(cvmfs_test_file):
            cmd = ['md5sum', cvmfs_test_file]
            p = Popen(cmd, stdout=PIPE)
            output = p.communicate()[0]
            if cvmfs_md5sum not in output:
                raise Exception()
        else:
            raise Exception()
        # If we got this far CVMFS must work
        print 'PYGLIDEIN_RESOURCE_CVMFS=True'
        print '- update:true'
    except:
        print 'PYGLIDEIN_RESOURCE_CVMFS=False'
        print '- update:true'


if __name__ == '__main__':
    main()

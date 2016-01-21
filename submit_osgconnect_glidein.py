#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

from submit_condor_glidein import SubmitCondor

class SubmitOSGConnect(SubmitCondor):
    def make_submit_file_custom(self,file):
        file.write('+ProjectName = "IceCube"\n')
        file.write('+osg_site_blacklist="OSCER_ATLAS"\n')
        file.write('Requirements = (HAS_CVMFS_icecube_opensciencegrid_org =?= True)\n')

if __name__ == '__main__':
    SubmitOSGConnect().submit()

#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

from submit_condor_glidein import SubmitCondor

class SubmitXsede(SubmitCondor):
    def make_submit_file_custom(self,file):
        file.write('+ProjectName = "TG-AST140088"\n')
        file.write('+osg_site_blacklist="OSCER_ATLAS"\n')

if __name__ == '__main__':
    SubmitXsede().submit()

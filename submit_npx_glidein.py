#!/usr/bin/env python
from __future__ import absolute_import, division, print_function

from submit_condor_glidein import SubmitCondor

class SubmitNPX(SubmitCondor):
    def get_custom_env(self):
        return {'http_proxy':'http://squid.icecube.wisc.edu:3128'}

if __name__ == '__main__':
    SubmitNPX().submit()

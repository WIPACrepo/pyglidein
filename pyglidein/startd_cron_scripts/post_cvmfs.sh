#!/bin/bash -e

eval `/cvmfs/icecube.opensciencegrid.org/py2-v2/setup.sh`

exec env $@

#!/bin/bash
exec 2>&1
. /home/condor/condor-8.7.2/condor.sh
/pyglidein/server.py -p 8001

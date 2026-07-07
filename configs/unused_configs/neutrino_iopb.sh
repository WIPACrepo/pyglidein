#!/bin/bash

echo `date`
echo $HOSTNAME

export MEMORY=250000 # 11600
# export WALLTIME=86400
export ACCEPT_JOBS_FOR_HOURS=24000
export ACCEPT_IDLE_MINUTES=200
export CPUS=128
export DISK=819200000000
export GPUS=0
export GLIDEIN_Site="IOPB"

GLIDEIN_LOC=/home/benedikt/pyglidein/pyglidein
WORK_DIR=/home/benedikt/pilot/
cd $WORK_DIR
cp $GLIDEIN_LOC/glidein_start.sh .


export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M
export GLIDEIN_ResourceName=$SITE

# Using Apptainer from CVMFS because it is more up-to-date
export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.2.5/x86_64/bin/apptainer

# Image below comes from docker://hub.opensciencegrid.org/opensciencegrid/osgvo-docker-pilot:3.6-release
# Not auto pulling cause OSG tends to make changes that break or change beahvior in unexpcted way
export BASE_IMAGE=/home/benedikt/osgvo-docker-pilot_23-release.sif
# /scratch/bbfw/riedel1/osgvo-docker-pilot_apptainer_nvidia_nvvm.sif
# /u/riedel1/osgvo-docker-pilot_gpu.sif
# /projects/bbfw/riedel1/osgvo-docker-pilot.sif


until ./glidein_start.sh; do
    echo "glidein_start.sh stopped wwith exit code $?.  Respawning.." >&2
    sleep 1
done       

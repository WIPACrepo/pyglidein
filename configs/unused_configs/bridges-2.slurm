#!/bin/bash
#SBATCH -N 1
#SBATCH -p GPU-shared
#SBATCH -t 48:00:00
#SBATCH --gpus=1
#SBATCH --job-name="glidein"
#SBATCH --output=/jet/home/briedel/out/%j.out
#SBATCH --error=/jet/home/briedel/out/%j.err


printenv

echo $LOCAL

export LOCAL_DIR=$LOCAL/$SLURM_JOBID
mkdir -p $LOCAL/$SLURM_JOBID
echo `date`

export MEMORY=60000
export WALLTIME=172500
export ACCEPT_JOBS_FOR_HOURS=48
export CPUS=5
export DISK=102400000
# if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then
#   GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
# elif [ "x$CUDA_VISIBLE_DEVICES" = "x" ] ; then
#   GPUS=1
# else
#   GPUS=$CUDA_VISIBLE_DEVICES
# fi
export GPUS="CUDA$SLURM_JOB_GPUS"
export GLIDEIN_Site="Bridges-2"
export CLEANUP=1

GLIDEIN_LOC=/jet/home/briedel/pyglidein2/pyglidein

cd $LOCAL_DIR

cp $GLIDEIN_LOC/glidein_start.sh .

export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M
export GLIDEIN_ResourceName=$SITE

# Using Apptainer from CVMFS because it is more up-to-date
export SINGULARITY_BIN=apptainer
# /cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.2.4/x86_64/bin/apptainer

export BASE_IMAGE=/jet/home/briedel/osgvo-docker-pilot_23-cuda_11_8_0-release.sif
# /jet/home/briedel/osgvo-docker-pilot_apptainer_nvidia_nvvm.sif

./glidein_start.sh


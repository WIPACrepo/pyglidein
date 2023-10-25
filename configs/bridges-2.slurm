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

mkdir -p $LOCAL/$SLURM_JOBID
echo `date`

MEMORY=60000
WALLTIME=172500
CPUS=5
DISK=102400000
# if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then
#   GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
# elif [ "x$CUDA_VISIBLE_DEVICES" = "x" ] ; then
#   GPUS=1
# else
#   GPUS=$CUDA_VISIBLE_DEVICES
# fi
GPUS="CUDA$SLURM_JOB_GPUS"
SITE="Bridges-2"
CLEANUP=1
LOCAL_DIR=$LOCAL/$SLURM_JOBID

GLIDEIN_LOC=/jet/home/briedel/pyglidein2/pyglidein

cd $LOCAL_DIR

cp $GLIDEIN_LOC/glidein_start.sh .

export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M
export ResourceName=$SITE

# Using Apptainer from CVMFS because it is more up-to-date
export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.2.4/x86_64/bin/apptainer

export BASE_IMAGE=/jet/home/briedel/osgvo-docker-pilot_apptainer_nvidia_nvvm.sif

./glidein_start.sh


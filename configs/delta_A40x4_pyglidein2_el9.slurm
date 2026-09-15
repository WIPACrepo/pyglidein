#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --partition=gpuA40x4      # <- or one of: gpuA100x4 gpuA40x4 gpuA100x8 gpuMI100x8
#SBATCH --account=bbfw-delta-gpu
#SBATCH --job-name=glidein
#SBATCH --time=2-00:00:00      # d-hh:mm:ss for the job
#SBATCH --cpus-per-task=16
#SBATCH --gpus-per-node=1
#SBATCH --tasks=1
#SBATCH --mem=56G
#SBATCH --array=1-7500
#SBATCH -o /scratch/bbfw/ehobert/logs/%A.%a.out  # File to which STDOUT will be written, %j inserts jobid
#SBATCH -e /scratch/bbfw/ehobert/logs/%A.%a.err  # File to which STDERR will be written, %j inserts jobid


module purge

echo `date`
echo $HOSTNAME

export MEMORY=56000 # 11600
export ACCEPT_JOBS_FOR_HOURS=48
export CPUS=16
export DISK=81920000000
if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then
  GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
elif [ "x$CUDA_VISIBLE_DEVICES" = "x" ] ; then
  GPUS=1
else
  GPUS=$CUDA_VISIBLE_DEVICES
fi
export GPUS=$GPUS
export GLIDEIN_Site="NCSA Delta"

GLIDEIN_LOC=/u/ehobert/pyglidein/pyglidein


# local disk is big enough
LOCAL_DIR=/tmp/${SLURM_ARRAY_JOB_ID}/${SLURM_ARRAY_TASK_ID}


mkdir -p ${LOCAL_DIR}
cd $LOCAL_DIR
cp -a /u/ehobert/cvmfsexec . 

ls ${LOCAL_DIR}/cvmfsexec
echo "---"

mkdir glidein
cd glidein
echo $PWD
cp $GLIDEIN_LOC/glidein_start.sh .


export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE3NjIzNzkzNjMsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6IjBiM2IzOGI5MzlkMGY0ZDM0ZDIwMDdjNWNlNjc1Mjk3Iiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0RBRU1PTiBjb25kb3I6XC9BRFZFUlRJU0VfU1RBUlREIGNvbmRvcjpcL0FEVkVSVElTRV9NQVNURVIiLCJzdWIiOiJweWdsaWRlaW5AaWNlY3ViZS53aXNjLmVkdSJ9.lM0ED5dEEWCEg1s5d4toNHk9vkbLapwgm6yx--OBcAE

# Using Apptainer from CVMFS because it is more up-to-date 
export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.2.5/x86_64/bin/apptainer

# Image comes from docker://hub.opensciencegrid.org/osg-htc/ospool-ep:25-cuda_11_8_0-release
# Not auto pulling cause OSG tends to make changes that break or change behavior in unexpected way
export BASE_IMAGE=/projects/bbfw/ehobert/ospool-ep_25-cuda_11_8_0-release.sif

export APPTAINERENV_CVMFS_QUOTA_LIMIT=120000

echo "Invoke the cvmfsexec env"
${LOCAL_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh

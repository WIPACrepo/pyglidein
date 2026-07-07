#!/bin/bash
#SBATCH --nodes=1
#SBATCH --partition=h100
#SBATCH --job-name=glidein
#SBATCH --time=48:00:00      # hh:mm:ss for the job
# #SBATCH --array=1-100
#SBATCH -o /scratch/04799/tg840985/logs/%A.%a.out
#SBATCH -e /scratch/04799/tg840985/logs/%A.%a.err


module purge

echo `date`
echo $HOSTNAME

nvidia-smi
echo $CUDA_VISIBLE_DEVICES
export CUDA_VISIBLE_DEVICES=0,1,2,3

export MEMORY=96000 # 11600
# export WALLTIME=86400
export ACCEPT_JOBS_FOR_HOURS=48
export CPUS=96
export DISK=819200000000
if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then
  GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
elif [ "x$CUDA_VISIBLE_DEVICES" = "x" ] ; then
  GPUS=1
else
  GPUS=$CUDA_VISIBLE_DEVICES
fi
export GPUS=$GPUS
export GLIDEIN_Site="TACC Stampede3"

GLIDEIN_LOC=/home1/04799/tg840985/pyglidein2/pyglidein

LOCAL_DIR=/tmp/${SLURM_JOBID}/${SLURM_ARRAY_TASK_ID}

CVMFSEXEC_DIR=/home1/04799/tg840985/cvmfsexec/

mkdir -p ${LOCAL_DIR}
cd $LOCAL_DIR
cp -a /home1/04799/tg840985/cvmfsexec .

ls ${LOCAL_DIR}/cvmfsexec
echo "---"


mkdir glidein
cd glidein
echo $PWD
cp $GLIDEIN_LOC/glidein_start.sh .


export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M
export ResourceName=$SITE


# Using Apptainer from CVMFS because it is more up-to-date
export SINGULARITY_BIN=/opt/apps/tacc-apptainer/1.4.1/bin/apptainer
# /cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.5.0/x86_64/bin/apptainer

export BASE_IMAGE=/home1/04799/tg840985/ospool-ep_25-cuda_11_8_0-release.sif
# osgvo-docker-pilot_25_cuda_11.8
# /scratch/bbfw/riedel1/osgvo-docker-pilot_apptainer_nvidia_nvvm.sif
# /u/riedel1/osgvo-docker-pilot_gpu.sif
# /projects/bbfw/riedel1/osgvo-docker-pilot.sif

export APPTAINERENV_CVMFS_QUOTA_LIMIT=120000

${LOCAL_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh

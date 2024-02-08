#!/bin/bash
#SBATCH -n 8                # Number of cores (-n)
#SBATCH -N 1                # Ensure that all cores are on one Node (-N)
#SBATCH -t 1-00:00          # Runtime in D-HH:MM, minimum of 10 minutes
#SBATCH -p gpu_requeue   # Partition to submit to
#SBATCH --mem=32000           # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --gres=gpu:1
#SBATCH -o /n/home00/briedel/out/%j.out  # File to which STDOUT will be written, %j inserts jobid
#SBATCH -e /n/home00/briedel/out/%j.err  # File to which STDERR will be written, %j inserts jobid


module purge

echo `date`
echo $HOSTNAME
echo "-----------------Removing FUSE mounts------------------"

# mount -l -t fuse | grep IceCube | awk -F " " '{print "fusermount -u " $3}' | bash

export MEMORY=32000
# WALLTIME=86400
export ACCEPT_JOBS_FOR_HOURS=24
export CPUS=8
export DISK=81920000000
if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then
  GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
elif [ "x$CUDA_VISIBLE_DEVICES" = "x" ] ; then
  GPUS=1
else
  GPUS=$CUDA_VISIBLE_DEVICES
fi
export GPU=$GPU
export GPU2=$(nvidia-smi --query-gpu=index --format=csv,noheader);
echo "GPU2=$GPU2"
echo "GPU=$GPUS"
export SITE="Harvard"


GLIDEIN_LOC=/n/home00/briedel/pyglidein2/pyglidein
# LOCAL_DIR=/n/holyscratch01/arguelles_delgado_lab/Lab/IceCube/iceprod/$SLURM_JOB_ID/

# LOCAL_DIR=/scratch/$SLURM_JOB_ID
LOCAL_DIR=/n/holyscratch01/arguelles_delgado_lab/Lab/IceCube/prod/$SLURM_JOB_ID/
# CVMFSEXEC_DIR=/n/holyscratch01/arguelles_delgado_lab/Lab/IceCube/cvmfsexec/
# CVMFSEXEC_DIR=/n/home00/briedel/cvmfsexec/


mkdir -p $LOCAL_DIR

ls ${LOCAL_DIR}/cvmfsexec
echo "---"


echo "-------Unmount repo------" | tee /dev/stderr 
# ${LOCAL_DIR}/cvmfsexec/umountrepo -a

echo "-------Mount repo------" | tee /dev/stderr


cd $LOCAL_DIR
echo $PWD

cp $GLIDEIN_LOC/glidein_start.sh glidein_start.sh

ls $PWD

echo '-------------------------------'


export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M

export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.2.5/x86_64/bin/apptainer
# singularity
# /cvmfs/oasis.opensciencegrid.org/mis/singularity/bin/singularity


export BASE_IMAGE=/n/home00/briedel/osgvo-docker-pilot_23-cuda_11_8_0-release.sif
# /n/home00/briedel/pyglidein2/osgvo-docker-pilot.sif

./glidein_start.sh




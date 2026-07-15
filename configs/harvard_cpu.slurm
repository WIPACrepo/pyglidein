#!/bin/bash
#SBATCH -c 8
#SBATCH -N 1                # Ensure that all cores are on one Node (-N)
#SBATCH -t 1-00:00          # Runtime in D-HH:MM, minimum of 10 minutes
#SBATCH -p serial_requeue   # Partition to submit to
#SBATCH --mem=32000           # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --array=1-1000
#SBATCH -o /n/home00/briedel/out/%A.%a.out  # File to which STDOUT will be written, %j inserts jobid
#SBATCH -e /n/home00/briedel/out/%A.%a.err  # File to which STDERR will be written, %j inserts jobid

module purge

echo `date`
echo $HOSTNAME
echo "-----------------Removing FUSE mounts------------------"

# mount -l -t fuse | grep IceCube | awk -F " " '{print "fusermount -u " $3}' | bash

export MEMORY=32000
# WALLTIME=86400
export ACCEPT_JOBS_FOR_HOURS=24
export ACCEPT_IDLE_MINUTES=60
export CPUS=8
export DISK=81920000000
# if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then
#   GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
# elif [ "x$CUDA_VISIBLE_DEVICES" = "x" ] ; then
#   GPUS=1
# else
#   GPUS=$CUDA_VISIBLE_DEVICES
# fi
# export GPUS=$GPUS
# export GPU2=$(nvidia-smi --query-gpu=index --format=csv,noheader);
# echo "GPU2=$GPU2"
# echo "GPUS=$GPUS"
export GLIDEIN_Site="Harvard"


GLIDEIN_LOC=/n/home00/briedel/pyglidein2/pyglidein
# LOCAL_DIR=/n/holyscratch01/arguelles_delgado_lab/Lab/IceCube/iceprod/$SLURM_JOB_ID/

# LOCAL_DIR=/scratch/$SLURM_JOB_ID
LOCAL_DIR=/n/netscratch/arguelles_delgado_lab/Lab/IceCube/prod/$SLURM_JOB_ID/$SLURM_ARRAY_TASK_ID
# CVMFSEXEC_DIR=/n/holyscratch01/arguelles_delgado_lab/Lab/IceCube/cvmfsexec/
# CVMFSEXEC_DIR=/n/home00/briedel/cvmfsexec/

mkdir -p $LOCAL_DIR

test -d $LOCAL_DIR || exit 1

cd $LOCAL_DIR

cp $GLIDEIN_LOC/glidein_start.sh glidein_start.sh

ls $PWD

echo '-------------------------------'

# echo $CUDA_VISIBLE_DEVICES

# echo "CHECK MIG STATUS $(nvidia-smi --query-gpu=gpu_name,mig.mode.current --format=csv,noheader)"


# if [[ "$CUDA_VISIBLE_DEVICES" == *"MIG"* ]]; then
#     echo "MIG STATUS FROM CUDA_VISIBLE_DEVICES"
#     export NEED_CONDOR_EXTRA_ATTR=true
#     cp $GLIDEIN_LOC/configs/fir_extra-attributes.cfg ./extra-attributes.cfg
# fi

export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE3NjIzNzkzNjMsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6IjBiM2IzOGI5MzlkMGY0ZDM0ZDIwMDdjNWNlNjc1Mjk3Iiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0RBRU1PTiBjb25kb3I6XC9BRFZFUlRJU0VfU1RBUlREIGNvbmRvcjpcL0FEVkVSVElTRV9NQVNURVIiLCJzdWIiOiJweWdsaWRlaW5AaWNlY3ViZS53aXNjLmVkdSJ9.lM0ED5dEEWCEg1s5d4toNHk9vkbLapwgm6yx--OBcAE
# eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M

export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.4.2/x86_64/bin/apptainer
# singularity
# /cvmfs/oasis.opensciencegrid.org/mis/singularity/bin/singularity


export BASE_IMAGE=/n/holylabs/arguelles_delgado_lab/Lab/ospool-ep_25-cuda_11_8_0-release.sif
# /n/holylabs/arguelles_delgado_lab/Lab/osgvo-docker-pilot_23-cuda_11_8_0-release.sif
# /n/netscratch/arguelles_delgado_lab/Lab/IceCube/osgvo-docker-pilot_23-cuda_11_8_0-release.sif
# /n/home00/briedel/osgvo-docker-pilot_23-cuda_11_8_0-release.sif
# /n/home00/briedel/pyglidein2/osgvo-docker-pilot.sif

./glidein_start.sh


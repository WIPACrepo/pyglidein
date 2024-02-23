#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=5G
#SBATCH --partition=lonepeak-gpu
#SBATCH --account=lonepeak-gpu
#SBATCH --gres=gpu:1
#SBATCH --time=24:00:00
#SBATCH --output=/uufs/chpc.utah.edu/common/home/u6058313/logs/lp-%j.out
#SBATCH --error=/uufs/chpc.utah.edu/common/home/u6058313/logs/lp-%j.err



echo `date`
echo $HOSTNAME

module purge

nvidia-smi

echo "-----------------------------------------------------"
printenv
echo "-----------------------------------------------------"


# export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=memory.free,index --format=csv,nounits,noheader | sort -nr | head -1 | awk '{print $NF }')

export LOCAL_CVMFS_DIR=/scratch/local/$USER/$SLURM_JOB_ID

mkdir $LOCAL_CVMFS_DIR

cp -r /uufs/chpc.utah.edu/common/home/u6058313/cvmfsexec $LOCAL_CVMFS_DIR/cvmfsexec

export LOCAL_DIR=/scratch/general/vast/$USER/$SLURM_JOB_ID

mkdir -p ${LOCAL_DIR}

cd ${LOCAL_DIR}

export MEMORY=5000
export WALLTIME=86400
export CPUS=8
export DISK=147456000000
export GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
export GLIDEIN_Site="UofU Lonepeak"

echo $PWD

cp /uufs/chpc.utah.edu/common/home/u6058313/pyglidein2/pyglidein/glidein_start.sh glidein_start.sh

export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M

export SINGULARITY_BIN=/uufs/chpc.utah.edu/sys/installdir/apptainer/1.2.5/bin/apptainer
# /cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.2.5/x86_64/bin/apptainer

export BASE_IMAGE=/uufs/chpc.utah.edu/common/home/u6058313/osgvo-docker-pilot_3.6-cuda_11_8_0-release.sif

${LOCAL_CVMFS_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh

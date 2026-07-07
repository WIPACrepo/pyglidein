#!/bin/bash
#SBATCH --job-name="glidein"
#SBATCH --nodes=1
#SBATCH --partition=gpu-a100-small
#SBATCH --time=24:00:00
#SBATCH --output=/scratch/04799/tg840985/out/GPU_%j.out
#SBATCH --error=/scratch/04799/tg840985/out/GPU_%j.err
#SBATCH --export=ALL
#SBATCH -A PHY20012

echo `date`
echo $HOSTNAME

module purge

# module load cuda/11.3 

echo "-----------------------------------------------------"
printenv
echo "-----------------------------------------------------"
export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=memory.free,index --format=csv,nounits,noheader | sort -nr | head -1 | awk '{print $NF }')

echo $CUDA_VISIBLE_DEVICES

export LOCAL_CVMFS_DIR=/tmp/icecube/${SLURM_JOBID}

mkdir -p ${LOCAL_CVMFS_DIR}

cp -a /home1/04799/tg840985/cvmfsexec ${LOCAL_CVMFS_DIR}/cvmfsexec

export LOCAL_DIR=/scratch/04799/tg840985/${SLURM_JOBID}

mkdir -p ${LOCAL_DIR}

cd ${LOCAL_DIR}

export MEMORY=64000
export WALLTIME=86400
export CPUS=32
export DISK=147456000000
export GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
export GLIDEIN_Site="Lonestar6"
cd $LOCAL_DIR
echo $PWD

cp /home1/04799/tg840985/pyglidein2/pyglidein/glidein_start.sh glidein_start.sh


export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M

# Using Apptainer from CVMFS because it is more up-to-date
export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.2.5/x86_64/bin/apptainer

# Image below comes from docker://hub.opensciencegrid.org/opensciencegrid/osgvo-docker-pilot:3.6-release
# Not auto pulling cause OSG tends to make changes that break or change beahvior in unexpcted way
export BASE_IMAGE=/work/04799/tg840985/ls6/osgvo-docker-pilot_23-cuda_11_8_0-release.sif
#/scratch/bbfw/riedel1/osgvo-docker-pilot_apptainer_nvidia_nvvm.sif
# /u/riedel1/osgvo-docker-pilot_gpu.sif
# /projects/bbfw/riedel1/osgvo-docker-pilot.sif

APPTAINERENV_CVMFS_QUOTA_LIMIT=120000

echo "Invoke the cvmfsexec env"
${LOCAL_CVMFS_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh

#!/bin/bash
#SBATCH --job-name="glidein"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --partition=rtx
#SBATCH --time=24:00:00
#SBATCH --output=/scratch1/04799/tg840985/out/GPU_%j.out
#SBATCH --error=/scratch1/04799/tg840985/out/GPU_%j.err
#SBATCH --export=ALL
#SBATCH -A PHY20012

echo `date`
echo $HOSTNAME

module purge

echo "-----------------------------------------------------"
printenv
echo "-----------------------------------------------------"

export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=memory.free,index --format=csv,nounits,noheader | sort -nr | head -1 | awk '{print $NF }')

echo $CUDA_VISIBLE_DEVICES

export LOCAL_CVMFS_DIR=/tmp/icecube/${SLURM_JOBID}

mkdir -p ${LOCAL_CVMFS_DIR}

cp -a ${WORK}/cvmfsexec ${LOCAL_CVMFS_DIR}/cvmfsexec

export LOCAL_DIR=/scratch1/04799/tg840985/glideins/${SLURM_JOBID}

mkdir -p LOCAL_DIR

cd ${LOCAL_DIR}

export MEMORY=128000
export WALLTIME=86400
export CPUS=16
export DISK=147456000000
export GPUS="CUDA0,CUDA1,CUDA2,CUDA3"
export GLIDEIN_Site="Frontera"
echo $PWD
cp /home1/04799/tg840985/pyglidein2/pyglidein/glidein_start.sh glidein_start.sh

echo '-------------------------------'

export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmV
kdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcj
pcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ
_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M

echo "Start Glidein"
export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.2.5/x86_64/bin/apptainer

export BASE_IMAGE=/work2/04799/tg840985/frontera/osgvo-docker-pilot_23-cuda_11_8_0-release.sif
# /scratch/bbfw/riedel1/osgvo-docker-pilot_apptainer_nvidia_nvvm.sif

echo `date`

APPTAINERENV_CVMFS_QUOTA_LIMIT=120000

${LOCAL_CVMFS_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.o
rg icecube.opensciencegrid.org -- ./glidein_start.sh

echo `date`

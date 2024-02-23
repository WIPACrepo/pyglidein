#!/bin/bash
##NECESSARY JOB SPECIFICATIONS
#SBATCH --job-name=glidein       #Set the job name to "JobExample1"
#SBATCH --time=24:00:00              #Set the wall clock limit to 1hr and 30min
#SBATCH --ntasks=8                   #Request 1 task
#SBATCH --mem=5G                  #Request 2560MB (2.5GB) per node
#SBATCH --output=/home/u.br48903/logs/%j.out      #Send stdout/err to "Example1Out.[jobID]"
#SBATCH --error=/home/u.br48903/logs/%j.err
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1


echo `date`
echo $HOSTNAME

module purge

echo "-----------------------------------------------------"
printenv
echo "-----------------------------------------------------"

export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=memory.free,index --format=csv,nounits,noheader | sort -nr | head -1 | awk '{print $NF }')

echo $CUDA_VISIBLE_DEVICES

export LOCAL_DIR=/scratch/user/u.br48903/${SLURM_JOBID}


mkdir -p ${LOCAL_DIR}

cp -a ${HOME}/cvmfsexec ${LOCAL_DIR}/cvmfsexec

cd ${LOCAL_DIR}

export MEMORY=5000
export WALLTIME=86400
export CPUS=8
export DISK=147456000000
export GPUS="CUDA0"
export GLIDEIN_Site="TAMU FASTER"
echo $PWD
cp /home/u.br48903/pyglidein2/pyglidein/glidein_start.sh glidein_start.sh

echo '-------------------------------'

export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M


echo "Start Glidein"
export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.2.5/x86_64/bin/apptainer

export BASE_IMAGE=/scratch/user/u.br48903/osgvo-docker-pilot_3.6-cuda_11_8_0-release.sif
# /scratch/bbfw/riedel1/osgvo-docker-pilot_apptainer_nvidia_nvvm.sif

echo `date`

export APPTAINERENV_CVMFS_QUOTA_LIMIT=120000
export APPTAINERENV_RoomForCPUOnlyJobs=false


${LOCAL_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh

echo `date`

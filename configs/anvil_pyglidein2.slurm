#!/bin/sh -l
# FILENAME:  anvil.slurm
#SBATCH -A phy150040-gpu 
#SBATCH -p gpu  # the default queue is "wholenode" queue
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus-per-node=1
#SBATCH --time=24:00:00
#SBATCH --job-name glidein
#SBATCH --mem=119G
#SBATCH --cpus-per-task=32
#SBATCH --array=1-32
#SBATCH --output=/home/x-briedel/logs/%A.%a.out
#SBATCH --error=/home/x-briedel/logs/%A.%a.err

module --force purge

echo `date`
echo $HOSTNAME
printenv

export MEMORY=119000 # 11600
export ACCEPT_JOBS_FOR_HOURS=24
export CPUS=32
export DISK=81920000000
if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then
  GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
elif [ "x$CUDA_VISIBLE_DEVICES" = "x" ] ; then
  GPUS=1
else
  GPUS=$CUDA_VISIBLE_DEVICES
fi
export GPUS=$GPUS
export GLIDEIN_Site="Purdue Anvil"
export OSG_PROJECT_NAME=IceCube

JOB_DIR=/anvil/scratch/x-briedel/pyglidein/${SLURM_JOB_ID}/${SLURM_ARRAY_TASK_ID}
# /tmp/${SLURM_JOB_ID}
# /anvil/scratch/x-briedel/pyglidein/${SLURM_JOB_ID}

GLIDEIN_LOC=/home/x-briedel/pyglidein2/

mkdir -p ${JOB_DIR}
ls ${JOB_DIR}
cd ${JOB_DIR}

cp -r $PROJECT/cvmfsexec .

# cp $HOME/osgvo-pilot.sif .

# cp $GLIDEIN_LOC/osgvo-pilot-wip-bind.sif ./osgvo-pilot.sif 

cp $GLIDEIN_LOC/pyglidein/glidein_start.sh glidein_start.sh

export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.4.4/bin/apptainer
# /cvmfs/oasis.opensciencegrid.org/mis/apptainer/bin/apptainer
export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE3NjIzNzkzNjMsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6IjBiM2IzOGI5MzlkMGY0ZDM0ZDIwMDdjNWNlNjc1Mjk3Iiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0RBRU1PTiBjb25kb3I6XC9BRFZFUlRJU0VfU1RBUlREIGNvbmRvcjpcL0FEVkVSVElTRV9NQVNURVIiLCJzdWIiOiJweWdsaWRlaW5AaWNlY3ViZS53aXNjLmVkdSJ9.lM0ED5dEEWCEg1s5d4toNHk9vkbLapwgm6yx--OBcAE
# eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE3NjIzNzU0NzEsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6IjRlZTM0NzI3OTM2Y2M1YmY0YTBjM2NhZDJhZDk3NjA4Iiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0RBRU1PTiBjb25kb3I6XC9BRFZFUlRJU0VfU1RBUlREIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQiLCJzdWIiOiJweWdsaWRlaW5AaWNlY3ViZS53aXNjLmVkdSJ9.5jl9AmBq_YV-UUbEacpZOcQFHhM7yULT90l2Pk_Y1sU
# eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE3NjIzNzExNjYsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6IjI4MTQxNjdlOWMwZTUzNTgyNmVhNDZjYTBkM2UzMjJmIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX1NUQVJURCIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.1P-IP9fadk2SqL7QOcVduMVY7WPkOCrQCNUhDM76gi0
# eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M
# ls ${JOB_DIR}/cvmfsexec/dist/cvmfs/icecube.opensciencegrid.org/

export BASE_IMAGE=$PROJECT/ospool-ep_25-cuda_11_8_0-release.sif
# osgvo-docker-pilot_23-cuda_11_8_0-release.sif
# osgvo-pilot.sif

export _condor_NETWORK_INTERFACE='172.18.*'
export _condor_MASTER_DEBUG=D_HOSTNAME:2,D_ALWAYS:2

${JOB_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh 

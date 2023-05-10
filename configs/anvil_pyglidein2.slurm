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
#SBATCH --output=/home/x-briedel/logs/%j.out
#SBATCH --error=/home/x-briedel/logs/%j.err

module purge

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
export GLIDEIN_Site="Anvil"



JOB_DIR=/anvil/scratch/x-briedel/pyglidein/${SLURM_JOB_ID}

GLIDEIN_LOC=/home/x-briedel/pyglidein2/

mkdir -p ${JOB_DIR}
ls ${JOB_DIR}
cd ${JOB_DIR}

cp -r $PROJECT/cvmfsexec .

# cp $HOME/osgvo-pilot.sif .

# cp $GLIDEIN_LOC/osgvo-pilot-wip-bind.sif ./osgvo-pilot.sif 

cp $GLIDEIN_LOC/pyglidein/glidein_start.sh glidein_start.sh

export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/bin/apptainer
export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M
# ls ${JOB_DIR}/cvmfsexec/dist/cvmfs/icecube.opensciencegrid.org/

export BASE_IMAGE=$PROJECT/osgvo-pilot.sif

${JOB_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh 

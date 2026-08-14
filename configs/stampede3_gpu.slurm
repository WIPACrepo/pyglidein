#!/bin/bash
#SBATCH --nodes=1
#SBATCH --partition=h100
#SBATCH --job-name=glidein
#SBATCH --time=48:00:00      # hh:mm:ss for the job
# #SBATCH --array=1-100
#SBATCH -o /scratch/11739/ehobert/logs/%A.%a.out
#SBATCH -e /scratch/11739/ehobert/logs/%A.%a.err


module purge

echo `date`
echo $HOSTNAME

# for testing on ...
export MEMORY=1000000 # 1tb ram :o
export CPUS=96
export DISK=3000000000

nvidia-smi
echo $CUDA_VISIBLE_DEVICES

export CUDA_VISIBLE_DEVICES=0,1,2,3
export GPUS=CUDA0,CUDA1,CUDA2,CUDA3
echo $CUDA_VISIBLE_DEVICES
echo $GPUS

export ACCEPT_JOBS_FOR_HOURS=48
export ACCEPT_IDLE_MINUTES=20
export GLIDEIN_Site="TACC Stampede3"

export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M

LOCAL_DIR=/tmp/${SLURM_JOBID}/${SLURM_ARRAY_TASK_ID}

export SINGULARITY_BIN=/opt/apps/tacc-apptainer/1.4.1/bin/apptainer
export BASE_IMAGE=$HOME/glideins/ospool-ep_25-cuda_11_8_0-release.sif
export APPTAINERENV_OSG_DEFAULT_CONTAINER_CVMFS=1

# todo: what's this?
export APPTAINERENV_CVMFS_QUOTA_LIMIT=120000

mkdir -p ${LOCAL_DIR}
cd $LOCAL_DIR
cp -a $HOME/cvmfsexec/ .
echo "---"

mkdir glidein
cd glidein
echo $PWD
cp $HOME/glideins/pyglidein2/pyglidein/glidein_start.sh .


${LOCAL_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh

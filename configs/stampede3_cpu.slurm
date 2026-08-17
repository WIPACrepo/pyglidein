#!/bin/bash
#SBATCH --nodes=1
#SBATCH --partition=skx
#SBATCH --job-name=glidein
#SBATCH --time=48:00:00      # hh:mm:ss for the job
# 40 tasks at most 4 in parallel; elements count toward the 40 job/user skx cap
#SBATCH --array=1-40%4
#SBATCH -o /scratch/11739/ehobert/logs/%A.%a.out
#SBATCH -e /scratch/11739/ehobert/logs/%A.%a.err


module purge

echo `date`
echo $HOSTNAME

export MEMORY=180000 # skx: 192 GB/node, leaves headroom for os
export CPUS=48
export DISK=90000000 # skx: 90 GB /tmp in KB

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

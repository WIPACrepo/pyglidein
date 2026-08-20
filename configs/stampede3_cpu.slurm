#!/bin/bash
#SBATCH --nodes=1
#SBATCH --partition=icx
#SBATCH --job-name=glidein
#SBATCH --time=48:00:00      # hh:mm:ss for the job
# 12 tasks at most 4 in parallel; elements count toward the 12 job/user icx cap
#SBATCH --array=1-12%4
#SBATCH -o /scratch/11739/ehobert/logs/%A.%a.out
#SBATCH -e /scratch/11739/ehobert/logs/%A.%a.err


module purge

echo `date`
echo $HOSTNAME

export MEMORY=250000 # icx: 256 GB/node, leaves headroom for os
export CPUS=80
# unlike the gpu nodes node-local storage is limited (200 gb /tmp on icx)
# so the pilot sandbox lives on scratch to advertise enough storage
export DISK=1000000000 # 1tb

export ACCEPT_JOBS_FOR_HOURS=48
export ACCEPT_IDLE_MINUTES=20
export GLIDEIN_Site="TACC Stampede3"

export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M

# node-local tmp holds the cvmfsexec dist so its cache (dist/var/lib/cvmfs) stays on local disk
TMP_DIR=/tmp/${SLURM_JOBID}
# scratch holds the pilot sandbox with enough room to advertise 1 tb of disk
PILOT_DIR=$SCRATCH/glideins/${SLURM_ARRAY_JOB_ID}/${SLURM_ARRAY_TASK_ID}

export SINGULARITY_BIN=/opt/apps/tacc-apptainer/1.4.1/bin/apptainer
export BASE_IMAGE=$HOME/glideins/ospool-ep_25-cuda_11_8_0-release.sif
export APPTAINERENV_OSG_DEFAULT_CONTAINER_CVMFS=1

export APPTAINERENV_CVMFS_QUOTA_LIMIT=120000

mkdir -p ${TMP_DIR} ${PILOT_DIR}
cp -a $HOME/cvmfsexec/ ${TMP_DIR}/
echo "---"

cd ${PILOT_DIR}
echo $PWD
cp $HOME/glideins/pyglidein2/pyglidein/glidein_start.sh .


${TMP_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh

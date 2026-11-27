#!/bin/bash
#SBATCH -A m1093_g
#SBATCH -C gpu
#SBATCH -q shared_overrun
#SBATCH -t 24:00:00
# overrun requires --time-min, and slurm may grant less than -t if that lets us backfill
#SBATCH --time-min=12:00:00
# preempt mode is REQUEUE, so without this a preempted task is cancelled instead of re-queued
#SBATCH --requeue
# keep earlier attempts' logs across requeues
#SBATCH --open-mode=append
#SBATCH -J perlmutter_gpu_overrun
#SBATCH -n 1
#SBATCH --ntasks-per-node=1
#SBATCH -c 32
#SBATCH --gpus-per-node=1
#SBATCH --gpu-bind=none
# no throttle, take whatever they give us
#SBATCH --array=0-200
#SBATCH --output=/global/homes/i/icecubed/glideins/out/%A.%a.out
#SBATCH --error=/global/homes/i/icecubed/glideins/out/%A.%a.err
#SBATCH --module=cvmfs

module purge

# slurm seems to allocate mem=57472M in reality, as opposed to the nominal 64GB
export MEMORY=57000
export CPUS=16
export GPUS=CUDA0

# for some reason SLURM_JOB_END_TIME seems to reflect the minimum rather than the actually granted time
# so for now we're just defaulting to that until i find a way to grab the full scheduled time
export ACCEPT_JOBS_FOR_HOURS=12
echo "accept_jobs start=${SLURM_JOB_START_TIME:-unset} end=${SLURM_JOB_END_TIME:-unset} ACCEPT_JOBS_FOR_HOURS=$ACCEPT_JOBS_FOR_HOURS"

# idle costs nothing here, so keep the slot warm to catch demand spikes
export ACCEPT_IDLE_MINUTES=60
export DISK=819200000
export GLIDEIN_Site="NERSC"

LOCAL_DIR=$PSCRATCH/glideins/$SLURM_ARRAY_JOB_ID/$SLURM_ARRAY_TASK_ID/

export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M

# version 1.4.2 gives a libsubid.so.3 missing error, 1.3.3 seems to work
export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.3.3/x86_64/bin/apptainer
export BASE_IMAGE=$HOME/glideins/ospool-ep_25-cuda_11_8_0-release.sif
export APPTAINERENV_OSG_DEFAULT_CONTAINER_CVMFS=1

mkdir -p $LOCAL_DIR

cd $LOCAL_DIR

cp $HOME/glideins/pyglidein2/pyglidein/glidein_start.sh .


echo "SLURM_JOB_GPUS=$SLURM_JOB_GPUS"
echo "nproc=$(nproc)"
nvidia-smi -L

./glidein_start.sh

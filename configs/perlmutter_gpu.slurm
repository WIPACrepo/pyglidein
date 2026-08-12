#!/bin/bash
#SBATCH -A m1093_g
#SBATCH -C gpu
#SBATCH -q regular
#SBATCH -t 24:00:00
#SBATCH -n 1
#SBATCH --ntasks-per-node=1
#SBATCH -c 128
#SBATCH --gpus-per-node=4
#SBATCH --gpu-bind=none
# small array for now, don't have a ton of budget so wanna use it wisely
#SBATCH --array=0-10
#SBATCH --output=/global/homes/i/icecubed/glideins/out/%A.%a.out
#SBATCH --error=/global/homes/i/icecubed/glideins/out/%A.%a.err
#SBATCH --module=cvmfs

module purge

export MEMORY=256000
export CPUS=64
export GPUS=CUDA0,CUDA1,CUDA2,CUDA3

export ACCEPT_JOBS_FOR_HOURS=24
# keeping this small cause we don't have a ton of budget on this cluster
export ACCEPT_IDLE_MINUTES=20
export DISK=819200000
export GLIDEIN_Site="NERSC"

LOCAL_DIR=/pscratch/sd/i/icecubed/glideins/$SLURM_ARRAY_JOB_ID/$SLURM_ARRAY_TASK_ID/

export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M

# version 1.4.2 gives a libsubid.so.3 missing error, 1.3.3 seems to work
export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.3.3/x86_64/bin/apptainer
export BASE_IMAGE=/global/homes/i/icecubed/glideins/ospool-ep_25-cuda_11_8_0-release.sif
export APPTAINERENV_OSG_DEFAULT_CONTAINER_CVMFS=1

mkdir -p $LOCAL_DIR

cd $LOCAL_DIR

cp $HOME/glideins/pyglidein2/pyglidein/glidein_start.sh .


echo "SLURM_JOB_GPUS=$SLURM_JOB_GPUS"
echo "nproc=$(nproc)"
nvidia-smi -L

./glidein_start.sh

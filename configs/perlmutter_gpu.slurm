#!/bin/bash
#SBATCH -A m1093_g
#SBATCH -C gpu
#SBATCH -q regular
# #SBATCH -q debug
#SBATCH -t 12:00:00
#SBATCH -n 1
#SBATCH --ntasks-per-node=1
#SBATCH -c 32
#SBATCH --gpus-per-task=1
#SBATCH --gpu-bind=none
#SBATCH --output=/global/homes/b/briedel/out/%j.out
#SBATCH --error=/global/homes/b/briedel/out/%j.err

export MEMORY=256000
export ACCEPT_JOBS_FOR_HOURS=24
export ACCEPT_IDLE_MINUTES=40
export CPUS=64
export DISK=819200000
export GPUS=CUDA0,CUDA1,CUDA2,CUDA3
export GLIDEIN_Site="NERSC"
CLEANUP=0
LOCAL_DIR=/pscratch/sd/b/briedel/icecube/iceprod/$SLURM_JOB_ID


export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M

export SINGULARITY_BIN=/global/homes/b/briedel/apptainer/bin/apptainer
export BASE_IMAGE=/global/homes/b/briedel/osgvo-docker-pilot_23-cuda_11_8_0-release.sif
# /u/riedel1/osgvo-docker-pilot_23-cuda_11_8_0-release.sif
# /cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.2.5/x86_64/bin/apptainer

mkdir -p $LOCAL_DIR

cd $LOCAL_DIR

cp $HOME/pyglidein2/pyglidein/glidein_start.sh .


./glidein_start.sh


# podman-hpc run --gpu --cvmfs --net -v $LOCAL_DIR:/pilot -e MEMORY=256000 -e WALLTIME=86100 -e CPUS=64 -e DISK=819200000 -e GPUS=CUDA0,CUDA1,CUDA2,CUDA3 -e GLIDEIN_Site="NERSC"  
# opensciencegrid/osgvo-docker-pilot:23-cuda_11_8_0-release 

# shifter --image=docker:registry.services.nersc.gov/briedel/osgvo-el7-cuda11-opencl --module=gpu,cvmfs env CPUS=$CPUS GPUS=$GPUS MEMORY=$MEMORY DISK=$DISK WALLTIME=$WALLTIME DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS SITE=$SITE ResourceName=ResourceName GLIDEIN_DIR=$HOME/icecube/pyglidein/pyglidein ./glidein_start.sh

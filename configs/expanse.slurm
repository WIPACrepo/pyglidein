#!/bin/bash
#SBATCH --job-name="glidein"
#SBATCH --output="/home/briedel/out/gpu-shared.%j.out"
#SBATCH --error="/home/briedel/out/gpu-shared.%j.err"
#SBATCH --partition=gpu-shared
#SBATCH --nodes=1
#SBATCH --gpus=1
#SBATCH --mem=96G
#SBATCH --ntasks-per-node=10
#SBATCH -A wis142
#SBATCH -t 48:00:00

LOCAL_DIR=/scratch/$USER/job_$SLURM_JOB_ID

module purge

echo `date`

MEMORY=96000
WALLTIME=172500
CPUS=10
DISK=102400000
GPUS="CUDA$SLURM_JOB_GPUS"
GPUS_SINGULARITY="CUDA0"
SITE="Expanse"
CLEANUP=0


cd $LOCAL_DIR


GLIDEIN_LOC=/home/briedel/pyglidein2/pyglidein

cp $GLIDEIN_LOC/glidein_start.sh .

export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M
export ResourceName=$SITE

# Using Apptainer from CVMFS because it is more up-to-date
export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.2.4/x86_64/bin/apptainer

export BASE_IMAGE=/home/briedel/osgvo-docker-pilot_apptainer_nvidia_nvvm.sif

./glidein_start.sh

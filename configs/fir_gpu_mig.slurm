#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1    # <- match to OMP_NUM_THREADS
#SBATCH --account=rpp-nahee
#SBATCH --job-name=glidein
#SBATCH --time=24:00:00      # hh:mm:ss for the job
#SBATCH --cpus-per-task=2
#SBATCH --gpus=nvidia_h100_80gb_hbm3_1g.10gb:1
#SBATCH --tasks=1
#SBATCH --mem=5G
#SBATCH --array=1-7500
#SBATCH -o /scratch/briedel/logs/%A.%a.out  # File to which STDOUT will be written, %j inserts jobid
#SBATCH -e /scratch/briedel/logs/%A.%a.err  # File to which STDERR will be written, %j inserts jobid

module --force purge

echo `date`
echo $HOSTNAME

export MEMORY=$SLURM_MEM_PER_NODE # 11600
# export WALLTIME=86400
export ACCEPT_JOBS_FOR_HOURS=24
export CPUS=$SLURM_CPUS_PER_TASK
export DISK=81920000000
if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then
  GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
elif [ "x$CUDA_VISIBLE_DEVICES" = "x" ] ; then
  GPUS=1
else
  GPUS=$CUDA_VISIBLE_DEVICES
fi

export GPUS=$GPUS
export GLIDEIN_Site="Fir"

GLIDEIN_LOC=$HOME/pyglidein2/

LOCAL_DIR=${SLURM_TMPDIR}/
#/scratch/briedel/jobs/${SLURM_JOBID}/${SLURM_ARRAY_TASK_ID}/

mkdir -p ${LOCAL_DIR}
cd $LOCAL_DIR
echo "---"

touch ${LOCAL_DIR}/help

mkdir glidein
cd glidein
echo $PWD
cp $GLIDEIN_LOC/pyglidein/glidein_start.sh .


export NEED_CONDOR_EXTRA_ATTR=true
cp $GLIDEIN_LOC/configs/fir_extra-attributes.cfg ./extra-attributes.cfg

export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE3NjIzNzkzNjMsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6IjBiM2IzOGI5MzlkMGY0ZDM0ZDIwMDdjNWNlNjc1Mjk3Iiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0RBRU1PTiBjb25kb3I6XC9BRFZFUlRJU0VfU1RBUlREIGNvbmRvcjpcL0FEVkVSVElTRV9NQVNURVIiLCJzdWIiOiJweWdsaWRlaW5AaWNlY3ViZS53aXNjLmVkdSJ9.lM0ED5dEEWCEg1s5d4toNHk9vkbLapwgm6yx--OBcAE
# eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE3NjIzNzExNjYsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6IjI4MTQxNjdlOWMwZTUzNTgyNmVhNDZjYTBkM2UzMjJmIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX1NUQVJURCIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.1P-IP9fadk2SqL7QOcVduMVY7WPkOCrQCNUhDM76gi0
# eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M
export ResourceName=$SITE

# Using Apptainer from CVMFS because it is more up-to-date
export SINGULARITY_BIN=/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/apptainer/1.3.5/bin/apptainer
# /cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.4.2/x86_64/bin/apptainer

# Image below comes from docker://hub.opensciencegrid.org/opensciencegrid/osgvo-docker-pilot:3.6-release
# Not auto pulling cause OSG tends to make changes that break or change beahvior in unexpcted way
export BASE_IMAGE=/scratch/briedel/osgvo-docker-pilot_23-cuda_11_8_0-release.sif

nvidia-smi dmon > $SCRATCH/test-nvidia-smi.${SLURM_ARRAY_JOB_ID}.${SLURM_ARRAY_TASK_ID}.log &

# ${LOCAL_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- 
./glidein_start.sh

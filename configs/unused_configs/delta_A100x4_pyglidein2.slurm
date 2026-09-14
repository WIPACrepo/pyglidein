#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1    # <- match to OMP_NUM_THREADS
#SBATCH --partition=gpuA100x4      # <- or one of: gpuA100x4 gpuA40x4 gpuA100x8 gpuMI100x8
#SBATCH --account=bbfw-delta-gpu
#SBATCH --job-name=glidein
#SBATCH --time=24:00:00      # hh:mm:ss for the job
#SBATCH --cpus-per-task=14
#SBATCH --gpus-per-node=1
#SBATCH --tasks=1
#SBATCH --mem=56G
#SBATCH -o /scratch/bbfw/riedel1/logs/%j.out  # File to which STDOUT will be written, %j inserts jobid
#SBATCH -e /scratch/bbfw/riedel1/logs/%j.err  # File to which STDERR will be written, %j inserts jobid



echo `date`
echo $HOSTNAME

export MEMORY=56000 # 11600
# export WALLTIME=86400
export ACCEPT_JOBS_FOR_HOURS=24
export CPUS=14
export DISK=81920000000
if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then
  GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
elif [ "x$CUDA_VISIBLE_DEVICES" = "x" ] ; then
  GPUS=1
else
  GPUS=$CUDA_VISIBLE_DEVICES
fi
export GPUS=$GPUS
export GLIDEIN_Site="NCSA Delta"

GLIDEIN_LOC=/u/riedel1/pyglidein2/pyglidein

LOCAL_DIR=/tmp/${SLURM_JOBID}
CVMFSEXEC_DIR=/u/riedel1/cvmfsexec/


mkdir -p ${LOCAL_DIR}
cd $LOCAL_DIR
cp -a /u/riedel1/cvmfsexec .

ls ${LOCAL_DIR}/cvmfsexec
echo "---"

mkdir glidein
cd glidein
echo $PWD
# cp /u/riedel1/osgvo-pilot.sif .
# cp /projects/bbfw/riedel1/osgvo-docker-pilot-wip-binds.sif ./osgvo-pilot.sif
cp $GLIDEIN_LOC/glidein_start.sh .


export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M
export ResourceName=$SITE

# Using Apptainer from CVMFS because it is more up-to-date
export SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.2.5/x86_64/bin/apptainer

# Image below comes from docker://hub.opensciencegrid.org/opensciencegrid/osgvo-docker-pilot:3.6-release
# Not auto pulling cause OSG tends to make changes that break or change beahvior in unexpcted way
export BASE_IMAGE=/u/riedel1/osgvo-docker-pilot_23-cuda_11_8_0-release.sif
# /scratch/bbfw/riedel1/osgvo-docker-pilot_apptainer_nvidia_nvvm.sif
# /u/riedel1/osgvo-docker-pilot_gpu.sif
# /projects/bbfw/riedel1/osgvo-docker-pilot.sif

echo "Invoke the cvmfsexec env"
${LOCAL_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh

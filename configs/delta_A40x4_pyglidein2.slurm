#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1    # <- match to OMP_NUM_THREADS
#SBATCH --partition=gpuA40x4      # <- or one of: gpuA100x4 gpuA40x4 gpuA100x8 gpuMI100x8
#SBATCH --account=bbfw-delta-gpu
#SBATCH --job-name=glidein
#SBATCH --time=24:00:00      # hh:mm:ss for the job
#SBATCH --cpus-per-task=14
#SBATCH --gpus-per-node=1
#SBATCH --tasks=1
#SBATCH --mem=56G
#SBATCH -o /u/riedel1/logs/%j.out  # File to which STDOUT will be written, %j inserts jobid
#SBATCH -e /u/riedel1/logs/%j.err  # File to which STDERR will be written, %j inserts jobid



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
export GLIDEIN_Site="Delta"

GLIDEIN_LOC=/u/riedel1/pyglidein2/pyglidein
# LOCAL_DIR=/n/holyscratch01/arguelles_delgado_lab/Lab/IceCube/iceprod/$SLURM_JOB_ID/

# LOCAL_DIR=/scratch/$SLURM_JOB_ID
LOCAL_DIR=/tmp/
# $SLURM_JOB_ID
# CVMFSEXEC_DIR=/n/holyscratch01/arguelles_delgado_lab/Lab/IceCube/cvmfsexec/
CVMFSEXEC_DIR=/u/riedel1/cvmfsexec/


mkdir -p ${LOCAL_DIR}
cd $LOCAL_DIR
cp -a /u/riedel1/cvmfsexec . 
# cp /u/riedel1/pyglidein2/osgvo-docker-pilot.sif .

# ${LOCAL_DIR}


ls ${LOCAL_DIR}/cvmfsexec
echo "---"

mkdir glidein
cd glidein
echo $PWD
cp /u/riedel1/osgvo-pilot.sif .

cp $GLIDEIN_LOC/glidein_start.sh .
# cp $GLIDEIN_LOC/os_arch.sh .
# cp $GLIDEIN_LOC/log_shipper.sh .
# cp $GLIDEIN_LOC/startd_cron_scripts/clsim_gpu_test.py .
# cp $GLIDEIN_LOC/startd_cron_scripts/cvmfs_test.py .
# cp $GLIDEIN_LOC/startd_cron_scripts/gridftp_test.py .
# cp $GLIDEIN_LOC/startd_cron_scripts/post_cvmfs.sh .
# cp $GLIDEIN_LOC/startd_cron_scripts/pre_cvmfs.sh .


export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M
# SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/bin/apptainer
# export SITE=$SITE 
export ResourceName=$SITE

# ./glidein_start.sh

/tmp/cvmfsexec/cvmfsexec oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh
 

# ./glidein_start.sh
# SINGULARITY_BIN=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/bin/apptainer 
# DISK=$DISK ls $PWD
# SINGULARITY_BIN="/cvmfs/oasis.opensciencegrid.org/mis/apptainer/bin/apptainer" DISK=$DISK CPUS=$CPUS GPUS=$GPUS MEMORY=$MEMORY WALLTIME=$WALLTIME SITE=$SITE ResourceName=$SITE DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS ./glidein_start.sh # CVMFS_BASE_DIR=/tmp/cvmfsexec/dist/cvmfs ./glidein_start.sh

# export SINGCVMFS_REPOSITORIES="config-osg.opensciencegrid.org,oasis.opensciencegrid.org,icecube.opensciencegrid.org"

# /tmp/cvmfsexec/cvmfsexec oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- /cvmfs/oasis.opensciencegrid.org/mis/singularity/bin/singularity exec -B /etc/OpenCL --nv --bind /tmp/cvmfsexec/dist/cvmfs:/cvmfs --cleanenv --env DISK=$DISK,CPUS=$CPUS,GPUS=$GPUS,MEMORY=$MEMORY,WALLTIME=$WALLTIME,SITE=$SITE,ResourceName=$SITE,DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS /projects/bbfw/riedel1/osgvo-el7-cuda10_latest.sif ./glidein_start.sh




#  docker://opensciencegrid/osgvo-el7-cuda10 ./glidein_start.sh

# singcvmfs -s exec -cip --cleanenv --nv -B /etc/OpenCL -B /tmp --pwd $LOCAL_DIR/glidein --env DISK=$DISK,CPUS=$CPUS,GPUS=$GPUS,MEMORY=$MEMORY,WALLTIME=$WALLTIME,SITE=$SITE,ResourceName=$SITE,DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS docker://wipac/pyglidein-el8-cuda11:main ./glidein_start.sh
# /cvmfs/icecube.opensciencegrid.org/distrib/OpenCL_Linux/bin/x86_64/clinfo 
# ./glidein_start.sh

# ${LOCAL_DIR}/cvmfsexec/cvmfsexec 
# ${CVMFSEXEC_DIR}/cvmfsexec oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ls ${CVMFSEXEC_DIR}/cvmfsexec/dist/cvmfs

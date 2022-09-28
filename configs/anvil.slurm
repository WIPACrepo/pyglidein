#!/bin/sh -l
# FILENAME:  anvil.slurm
#SBATCH -A phy150040-gpu 
#SBATCH -p gpu  # the default queue is "wholenode" queue
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus-per-node=1
#SBATCH --time=24:00:00
#SBATCH --job-name glidein
#SBATCH --mem=120G
#SBATCH --cpus-per-task=60
#SBATCH --output=/home/x-briedel/logs/%j.out
#SBATCH --error=/home/x-briedel/logs/%j.err

module purge

echo `date`
echo $HOSTNAME
echo "-----------------Removing FUSE mounts------------------"

# mount -l -t fuse | grep IceCube | awk -F " " '{print "fusermount -u " $3}' | bash

MEMORY=60000 # 11600
WALLTIME=86400
CPUS=60
DISK=81920000000
if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then
  GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
elif [ "x$CUDA_VISIBLE_DEVICES" = "x" ] ; then
  GPUS=1
else
  GPUS=$CUDA_VISIBLE_DEVICES
fi
SITE="Anvil"



JOB_DIR=/anvil/scratch/x-briedel/pyglidein/${SLURM_JOB_ID}

GLIDEIN_LOC=/home/x-briedel/pyglidein/pyglidein

mkdir -p ${JOB_DIR}

cd ${JOB_DIR}

cp -r $PROJECT/cvmfsexec .


cp $GLIDEIN_LOC/glidein_start.sh glidein_start.sh
cp $GLIDEIN_LOC/os_arch.sh os_arch.sh
cp $GLIDEIN_LOC/log_shipper.sh log_shipper.sh
cp $GLIDEIN_LOC/startd_cron_scripts/clsim_gpu_test.py clsim_gpu_test.py
cp $GLIDEIN_LOC/startd_cron_scripts/cvmfs_test.py cvmfs_test.py
cp $GLIDEIN_LOC/startd_cron_scripts/gridftp_test.py gridftp_test.py
cp $GLIDEIN_LOC/startd_cron_scripts/post_cvmfs.sh post_cvmfs.sh
cp $GLIDEIN_LOC/startd_cron_scripts/pre_cvmfs.sh pre_cvmfs.sh

# ${JOB_DIR}/cvmfsexec/umountrepo -a
# ${JOB_DIR}/cvmfsexec/mountrepo config-osg.opensciencegrid.org
# ${JOB_DIR}/cvmfsexec/mountrepo icecube.opensciencegrid.org



# ls ${JOB_DIR}/cvmfsexec/dist/cvmfs/icecube.opensciencegrid.org/

${JOB_DIR}/cvmfsexec/cvmfsexec oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org --  /cvmfs/oasis.opensciencegrid.org/mis/singularity/bin/singularity exec -B /etc/OpenCL -B ${JOB_DIR} --nv --bind ${JOB_DIR}/cvmfsexec/dist/cvmfs:/cvmfs --cleanenv --env DISK=$DISK,CPUS=$CPUS,GPUS=$GPUS,MEMORY=$MEMORY,WALLTIME=$WALLTIME,SITE=$SITE,ResourceName=$SITE,DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS docker://opensciencegrid/osgvo-el7-cuda10 ./glidein_start.sh 

#!/bin/bash
#SBATCH -n 2                # Number of cores (-n)
#SBATCH -N 1                # Ensure that all cores are on one Node (-N)
#SBATCH -t 1-00:00          # Runtime in D-HH:MM, minimum of 10 minutes
#SBATCH -p gpu   # Partition to submit to
#SBATCH --mem=11600           # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --gres=gpu:1
#SBATCH -o /n/home00/briedel/out/%j.out  # File to which STDOUT will be written, %j inserts jobid
#SBATCH -e /n/home00/briedel/out/%j.err  # File to which STDERR will be written, %j inserts jobid


echo `date`
echo $HOSTNAME
echo "-----------------Removing FUSE mounts------------------"

# mount -l -t fuse | grep IceCube | awk -F " " '{print "fusermount -u " $3}' | bash

MEMORY=11600
WALLTIME=86400
CPUS=2
DISK=81920000000
if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then
  GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
elif [ "x$CUDA_VISIBLE_DEVICES" = "x" ] ; then
  GPUS=1
else
  GPUS=$CUDA_VISIBLE_DEVICES
fi
GPU2=$(nvidia-smi --query-gpu=index --format=csv,noheader);
echo "GPU2=$GPU2"
echo "GPU=$GPUS"
SITE="Harvard"

# df -h

GLIDEIN_LOC=/n/home00/briedel/pyglidein/pyglidein
# LOCAL_DIR=/n/holyscratch01/arguelles_delgado_lab/Lab/IceCube/iceprod/$SLURM_JOB_ID/

# LOCAL_DIR=/scratch/$SLURM_JOB_ID
LOCAL_DIR=/n/holyscratch01/arguelles_delgado_lab/Lab/IceCube/prod/$SLURM_JOB_ID/
# CVMFSEXEC_DIR=/n/holyscratch01/arguelles_delgado_lab/Lab/IceCube/cvmfsexec/
CVMFSEXEC_DIR=/n/home00/briedel/cvmfsexec/


mkdir -p $LOCAL_DIR

ls ${LOCAL_DIR}/cvmfsexec
echo "---"


echo "-------Unmount repo------" | tee /dev/stderr 
# ${LOCAL_DIR}/cvmfsexec/umountrepo -a

echo "-------Mount repo------" | tee /dev/stderr


cd $LOCAL_DIR
echo $PWD

cp $GLIDEIN_LOC/glidein_start.sh glidein_start.sh
cp $GLIDEIN_LOC/os_arch.sh os_arch.sh
cp $GLIDEIN_LOC/log_shipper.sh log_shipper.sh
cp $GLIDEIN_LOC/startd_cron_scripts/clsim_gpu_test.py clsim_gpu_test.py
cp $GLIDEIN_LOC/startd_cron_scripts/cvmfs_test.py cvmfs_test.py
cp $GLIDEIN_LOC/startd_cron_scripts/gridftp_test.py gridftp_test.py
cp $GLIDEIN_LOC/startd_cron_scripts/post_cvmfs.sh post_cvmfs.sh
cp $GLIDEIN_LOC/startd_cron_scripts/pre_cvmfs.sh pre_cvmfs.sh

ls $PWD

echo '-------------------------------'

echo $SITE
echo $GPUS

exec env -i CPUS=$CPUS GPUS=$GPUS MEMORY=$MEMORY DISK=$DISK WALLTIME=$WALLTIME DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS SITE=$SITE ResourceName=$SITE ./glidein_start.sh

# SINGULARITYENV_RETIRETIME=12000 SINGULARITYENV_NOCLAIMTIME=12000 
# SINGULARITYENV_DISK=$DISK SINGULARITYENV_CPUS=$CPUS SINGULARITYENV_GPUS=$GPUS SINGULARITYENV_MEMORY=$MEMORY SINGULARITYENV_WALLTIME=$WALLTIME SINGULARITYENV_DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS SINGULARITYENV_SITE=$SITE SINGULARITYENV_ResourceName=$SITE singularity exec -B /etc/OpenCL -B $LOCAL_DIR --nv --bind ${LOCAL_DIR}/cvmfsexec/dist/cvmfs:/cvmfs --cleanenv docker://opensciencegrid/osgvo-el7-cuda10 ./glidein_start.sh

# ${LOCAL_DIR}/cvmfsexec/cvmfsexec oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- SINGULARITYENV_DISK=$DISK SINGULARITYENV_CPUS=$CPUS SINGULARITYENV_GPUS=$GPUS SINGULARITYENV_MEMORY=$MEMORY SINGULARITYENV_WALLTIME=$WALLTIME SINGULARITYENV_DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS SINGULARITYENV_SITE=$SITE SINGULARITYENV_ResourceName=$SITE /cvmfs/oasis.opensciencegrid.org/mis/singularity/bin/singularity exec -B /etc/OpenCL -B $LOCAL_DIR --nv --bind ${LOCAL_DIR}/cvmfsexec/dist/cvmfs:/cvmfs --cleanenv docker://opensciencegrid/osgvo-el7-cuda10 ./glidein_start.sh



# exec env -i CPUS=$CPUS GPUS=$GPUS MEMORY=$MEMORY DISK=$DISK WALLTIME=$WALLTIME DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS SITE=$SITE ResourceName=ResourceName GLIDEIN_DIR=$GLIDEIN_LOC ./glidein_start.sh


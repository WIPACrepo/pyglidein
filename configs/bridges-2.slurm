#!/bin/bash
#SBATCH -N 1
#SBATCH -p GPU-shared
#SBATCH -t 48:00:00
#SBATCH --gpus=1
#SBATCH --job-name="glidein"
#SBATCH --output=/jet/home/briedel/out/%j.out
#SBATCH --error=/jet/home/briedel/out/%j.err
printenv
echo $LOCAL

mkdir -p $LOCAL/$SLURM_JOBID
echo `date`

MEMORY=60000
WALLTIME=172500
CPUS=5
DISK=102400000
# if [ "$CUDA_VISIBLE_DEVICES" -eq "$CUDA_VISIBLE_DEVICES" ] 2>/dev/null ; then
#   GPUS="CUDA${CUDA_VISIBLE_DEVICES}"
# elif [ "x$CUDA_VISIBLE_DEVICES" = "x" ] ; then
#   GPUS=1
# else
#   GPUS=$CUDA_VISIBLE_DEVICES
# fi
GPUS="CUDA$SLURM_JOB_GPUS"
SITE="Bridges-2"
CLEANUP=1
LOCAL_DIR=$LOCAL/$SLURM_JOBID


cd $LOCAL_DIR
cp /jet/home/briedel/pyglidein/pyglidein/glidein_start.sh glidein_start.sh
cp /jet/home/briedel/pyglidein/pyglidein/os_arch.sh os_arch.sh
cp /jet/home/briedel/pyglidein/pyglidein/log_shipper.sh log_shipper.sh
cp /jet/home/briedel/pyglidein/pyglidein/startd_cron_scripts/clsim_gpu_test.py clsim_gpu_test.py
cp /jet/home/briedel/pyglidein/pyglidein/startd_cron_scripts/cvmfs_test.py cvmfs_test.py
cp /jet/home/briedel/pyglidein/pyglidein/startd_cron_scripts/gridftp_test.py gridftp_test.py
cp /jet/home/briedel/pyglidein/pyglidein/startd_cron_scripts/post_cvmfs.sh post_cvmfs.sh
cp /jet/home/briedel/pyglidein/pyglidein/startd_cron_scripts/pre_cvmfs.sh pre_cvmfs.sh

echo $PWD
SINGULARITYENV_RETIRETIME=12000 SINGULARITYENV_DISK=$DISK SINGULARITYENV_CPUS=$CPUS SINGULARITYENV_GPUS=$GPUS SINGULARITYENV_MEMORY=$MEMORY SINGULARITYENV_WALLTIME=$WALLTIME SINGULARITYENV_DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS SINGULARITYENV_SITE=$SITE SINGULARITYENV_ResourceName=$SITE singularity exec --nv --bind /cvmfs/icecube.opensciencegrid.org --bind $LOCAL_DIR --bind /etc/OpenCL --cleanenv docker://opensciencegrid/osgvo-el7-cuda10 ./glidein_start.sh


if [ $CLEANUP -eq 1 ]; then
  rm -rf $LOCAL_DIR
fi
  rm -rf ${LOCAL_TMP_DIR}

echo `date`


#!/bin/bash
#SBATCH --nodes=1
#SBATCH --partition=pvc
#SBATCH --job-name=glidein
#SBATCH --time=48:00:00      # hh:mm:ss for the job
#SBATCH -o $SCRATCH/logs/%j.out
#SBATCH -e $SCRATCH/logs/%j.err


module purge

echo `date`
echo $HOSTNAME


export MEMORY=56000 # 11600
# export WALLTIME=86400
export ACCEPT_JOBS_FOR_HOURS=48
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
export GLIDEIN_Site="TACC Stampede3"

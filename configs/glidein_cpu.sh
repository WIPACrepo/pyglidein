#!/bin/bash
#SBATCH --job-name="glidein"
#SBATCH --nodes=1
#SBATCH --partition=regular
#SBATCH --time=24:00:00
#SBATCH --output=/global/u1/b/briedel/icecube/pyglidein/configs/out/%j.out
#SBATCH --error=/global/u1/b/briedel/icecube/pyglidein/configs/out/%j.err
# #SBATCH --volume="/global/cscratch1/sd/briedel/icecube/scratch/%j:/scratch"
#SBATCH --export=ALL
#SBATCH -A m1093
# #SBATCH --image=docker:benediktriedel/nersc-el7:latest
# #SBATCH --module=cvmfs
#SBATCH -L SCRATCH
#SBATCH -C haswell
MEMORY=120000
WALLTIME=86100
CPUS=64
DISK=819200000
GPUS=0
SITE="NERSC"
CLEANUP=0
LOCAL_DIR=/global/cscratch1/sd/$USER/icecube/scratch/$SLURM_JOB_ID
if [ ! -d $LOCAL_DIR ]; then
    mkdir -p $LOCAL_DIR
    CLEANUP=1
fi
cd $LOCAL_DIR
ln -fs /global/homes/b/briedel/icecube/pyglidein/pyglidein/glidein_start.sh glidein_start.sh
ln -fs /global/homes/b/briedel/icecube/pyglidein/pyglidein/os_arch.sh os_arch.sh
ln -fs /global/homes/b/briedel/icecube/pyglidein/pyglidein/log_shipper.sh log_shipper.sh
ln -fs /global/homes/b/briedel/icecube/pyglidein/pyglidein/startd_cron_scripts/clsim_gpu_test.py clsim_gpu_test.py
ln -fs /global/homes/b/briedel/icecube/pyglidein/pyglidein/startd_cron_scripts/cvmfs_test.py cvmfs_test.py
ln -fs /global/homes/b/briedel/icecube/pyglidein/pyglidein/startd_cron_scripts/gridftp_test.py gridftp_test.py
ln -fs /global/homes/b/briedel/icecube/pyglidein/pyglidein/startd_cron_scripts/post_cvmfs.sh post_cvmfs.sh
ln -fs /global/homes/b/briedel/icecube/pyglidein/pyglidein/startd_cron_scripts/pre_cvmfs.sh pre_cvmfs.sh
# exec 
shifter --image=docker:benediktriedel/nersc-el7:latest --module=cvmfs env -i CPUS=$CPUS GPUS=$GPUS MEMORY=$MEMORY DISK=$DISK WALLTIME=$WALLTIME DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS SITE=$SITE ResourceName=ResourceName GLIDEIN_DIR=$HOME/icecube/pyglidein/pyglidein ./glidein_start.sh
if [ $CLEANUP -eq 1 ]; then
    rm -rf $LOCAL_DIR
fi

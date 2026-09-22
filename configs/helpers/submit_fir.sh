#!/bin/bash

# keep the fir glidein fleets alive. intended crontab entry:
# 0 */4 * * * $HOME/pyglidein/configs/helpers/submit_fir.sh >> /scratch/ehobert/logs/cron.log 2>&1

# Getting the slurm executables into PATH
export PATH=$PATH:/opt/software/slurm/bin/

# exit on unset vars
set -u

# keep one pending job per glidein type; bump the limit to queue more sets
max_pending=1

pending=$(squeue -u "$USER" -h -t PENDING -p gpubase_bygpu_b3 -n glidein-mig-1slice | wc -l)
if [ "$pending" -le "$max_pending" ]; then
    echo "SUBMIT 1 slice"
    sbatch "$HOME/pyglidein/configs/fir_gpu_mig.slurm"
fi

pending=$(squeue -u "$USER" -h -t PENDING -p gpubase_bygpu_b3 -n glidein-mig-2slice | wc -l)
if [ "$pending" -le "$max_pending" ]; then
    echo "SUBMIT 2 slice"
    sbatch "$HOME/pyglidein/configs/fir_gpu_mig_2slices.slurm"
fi

pending=$(squeue -u "$USER" -h -t PENDING -p gpubase_bygpu_b3 -n glidein-mig-3slice | wc -l)
if [ "$pending" -le "$max_pending" ]; then
    echo "SUBMIT 3 slice"
    sbatch "$HOME/pyglidein/configs/fir_gpu_mig_3slices.slurm"
fi

pending=$(squeue -u "$USER" -h -t PENDING -p cpubase_bycore_b3 -n glidein | wc -l)
if [ "$pending" -le "$max_pending" ]; then
    echo "SUBMIT CPU"
    sbatch "$HOME/pyglidein/configs/fir_cpu.slurm"
fi

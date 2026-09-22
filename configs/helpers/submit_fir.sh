#!/bin/bash

# keep the fir glidein fleets alive. intended crontab entry:
# 0 */4 * * * $HOME/pyglidein/configs/helpers/submit_fir.sh >> /scratch/ehobert/logs/cron.log 2>&1

# Getting the slurm executables into PATH
export PATH=$PATH:/opt/software/slurm/bin/

# exit on unset vars
set -u

# --dry-run: print what would be submitted without touching the queue
dry_run=0
if [ "${1:-}" = "--dry-run" ]; then
    dry_run=1
fi

# keep up to max_pending pending jobs per glidein type; bump it to queue more sets
max_pending=1

pending=$(squeue -u "$USER" -h -t PENDING -p gpubase_bygpu_b3 -n glidein-mig-1slice | wc -l)
if [ "$pending" -lt "$max_pending" ]; then
    echo "SUBMIT 1 slice"
    if [ "$dry_run" -ne 1 ]; then
        sbatch "$HOME/pyglidein/configs/fir_gpu_mig.slurm"
    fi
fi

pending=$(squeue -u "$USER" -h -t PENDING -p gpubase_bygpu_b3 -n glidein-mig-2slice | wc -l)
if [ "$pending" -lt "$max_pending" ]; then
    echo "SUBMIT 2 slice"
    if [ "$dry_run" -ne 1 ]; then
        sbatch "$HOME/pyglidein/configs/fir_gpu_mig_2slices.slurm"
    fi
fi

pending=$(squeue -u "$USER" -h -t PENDING -p gpubase_bygpu_b3 -n glidein-mig-3slice | wc -l)
if [ "$pending" -lt "$max_pending" ]; then
    echo "SUBMIT 3 slice"
    if [ "$dry_run" -ne 1 ]; then
        sbatch "$HOME/pyglidein/configs/fir_gpu_mig_3slices.slurm"
    fi
fi

pending=$(squeue -u "$USER" -h -t PENDING -p cpubase_bycore_b3 -n glidein | wc -l)
if [ "$pending" -lt "$max_pending" ]; then
    echo "SUBMIT CPU"
    if [ "$dry_run" -ne 1 ]; then
        sbatch "$HOME/pyglidein/configs/fir_cpu.slurm"
    fi
fi

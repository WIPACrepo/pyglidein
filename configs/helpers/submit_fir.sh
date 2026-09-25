#!/bin/bash

# keep the fir glidein fleets alive. intended crontab entry:
# 0 */4 * * * $HOME/pyglidein/configs/helpers/submit_fir.sh >> /scratch/ehobert/logs/cron.log 2>&1

# Getting the slurm executables into PATH
export PATH=$PATH:/opt/software/slurm/bin/

# exit on unset vars
set -u

# keep up to max_pending pending jobs per glidein type; bump it to queue more sets
max_pending=1

# 1slice kept handy for sneaking into gaps; lower priority than 2slice/cpu
# pending=$(squeue -u "$USER" -h -t PENDING -n glidein-mig-1slice_72h | wc -l)
# if [ "$pending" -lt "$max_pending" ]; then
#     echo "SUBMIT 1 slice"
#     sbatch "$HOME/pyglidein/configs/fir_gpu_mig_72h.slurm"
# fi

pending=$(squeue -u "$USER" -h -t PENDING -n glidein-mig-2slice_72h | wc -l)
if [ "$pending" -lt "$max_pending" ]; then
    echo "SUBMIT 2 slice"
    sbatch "$HOME/pyglidein/configs/fir_gpu_mig_2slices_72h.slurm"
fi

pending=$(squeue -u "$USER" -h -t PENDING -n glidein_72h | wc -l)
if [ "$pending" -lt "$max_pending" ]; then
    echo "SUBMIT CPU"
    sbatch "$HOME/pyglidein/configs/fir_cpu_72h.slurm"
fi

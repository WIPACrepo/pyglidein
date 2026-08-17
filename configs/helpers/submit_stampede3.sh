#!/bin/bash

# intended crontab entry:
# (note: stampede3 has regular crontab, not scrontab. and it's per login node, so always gotta log in to the same one)
# 0 */4 * * * $HOME/glideins/pyglidein2/configs/helpers/submit_stampede3.sh >> /scratch/11739/ehobert/logs/cron.log 2>&1

# h100 allows up to 4 submitted jobs despite running only 2 at a time
max_h100_jobs=4
h100_count=$(squeue -u "$USER" -p h100 -h | grep "glidein" | wc -l)
if [ "$h100_count" -lt "$max_h100_jobs" ]; then
    echo "SUBMIT H100 ($h100_count of $max_h100_jobs in queue)"
    sbatch "$HOME/glideins/pyglidein2/configs/stampede3_gpu.slurm"
fi

# skx runs as a job array (--array=1-40%4)
# keep one array in flight and resubmit at the next cron tick when it drains
max_skx_jobs=1
skx_count=$(squeue -u "$USER" -p skx -h | grep "glidein" | wc -l)
if [ "$skx_count" -lt "$max_skx_jobs" ]; then
    echo "SUBMIT SKX ($skx_count of $max_skx_jobs in queue)"
    sbatch "$HOME/glideins/pyglidein2/configs/stampede3_cpu.slurm"
fi

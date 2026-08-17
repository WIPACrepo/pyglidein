#!/bin/bash

# intended crontab entry:
# (note: stampede3 has regular crontab, not scrontab. and it's per login node, so always gotta log in to the same one)
# 0 */4 * * * $HOME/glideins/pyglidein2/configs/helpers/submit_stampede3.sh >> /scratch/11739/ehobert/logs/cron.log 2>&1

# h100 allows up to 4 submitted jobs despite running only 2 at a time
max_jobs=4

count=$(squeue -u "$USER" -p h100 -h | grep "glidein" | wc -l)

if [ "$count" -lt "$max_jobs" ]; then
    echo "SUBMIT H100 ($count of $max_jobs in queue)"
    sbatch "$HOME/glideins/pyglidein2/configs/stampede3_gpu.slurm"
else
    exit
fi

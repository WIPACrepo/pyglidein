#!/bin/bash

# intended crontab entry:
# (note: stampede3 has regular crontab, not scrontab. and it's per login node, so always gotta log in to the same one)
# 0 */4 * * * $HOME/glideins/pyglidein2/configs/helpers/submit_stampede3.sh >> /scratch/11739/ehobert/logs/cron.log 2>&1

echo "== $(date '+%F %T') stampede3 top-up =="

# cron has a minimal env and sbatch doesn't work out of the box.
# source the full tacc env to ensure we can do our thing.
source /etc/profile 2>/dev/null

# exit on unset vars (after sourcing the profile to ensure we don't interfere there)
set -u

# clean up stale pilot scratch dirs; jobs max 48h so +3d is safe
find /scratch/11739/ehobert/glideins -mindepth 2 -maxdepth 2 -type d -mtime +3 -print0 \
    | xargs -0 -r -P 8 rm -rf

# h100 allows up to 4 submitted jobs despite running only 2 at a time
max_h100_jobs=4
h100_count=$(squeue -u "$USER" -p h100 -h | grep "glidein" | wc -l)
if [ "$h100_count" -lt "$max_h100_jobs" ]; then
    echo "$(date '+%F %T') SUBMIT H100 ($h100_count of $max_h100_jobs in queue)"
    sbatch "$HOME/glideins/pyglidein2/configs/stampede3_gpu.slurm"
fi

# icx runs as a job array (--array=1-12%4)
# keep one array in flight and resubmit when it drains
max_icx_jobs=1
icx_count=$(squeue -u "$USER" -p icx -h | grep "glidein" | wc -l)
if [ "$icx_count" -lt "$max_icx_jobs" ]; then
    echo "$(date '+%F %T') SUBMIT ICX ($icx_count of $max_icx_jobs in queue)"
    sbatch "$HOME/glideins/pyglidein2/configs/stampede3_cpu.slurm"
fi

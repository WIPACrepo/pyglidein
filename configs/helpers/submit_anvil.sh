#!/bin/bash

# no on-site cron/scrontab on anvil (verified in rcac docs), so this helper is
# meant to be triggered from an off-cluster machine via ssh. intended crontab entry:
# 0 */4 * * * ssh x-ehobert@anvil.rcac.purdue.edu "bash -lc '$HOME/glideins/pyglidein2/configs/helpers/submit_anvil.sh'" >> ~/pyglidein-anvil-cron.log 2>&1

set -u

# clean up old per-task scratch dirs (scratch auto-purges at 30 days, too slow for arrays)
find "$SCRATCH/glideins" -mindepth 2 -maxdepth 2 -type d -mtime +2 -print0 \
    | xargs -0 -r -P 8 rm -rf

# clean up old glidein logs (home quota is only 25 GB)
find "$HOME/logs" -type f -mtime +7 -delete

# refill the fleet only once the previous array has fully drained
count=$(squeue -u "$USER" -p gpu -h | grep -c "glidein" || true)
if [ "$count" -lt 1 ]; then
    echo "SUBMIT anvil glidein array (queue empty)"
    sbatch "$HOME/glideins/pyglidein2/configs/anvil_pyglidein2.slurm"
else
    echo "still $count glidein job(s) in queue, not resubmitting"
fi

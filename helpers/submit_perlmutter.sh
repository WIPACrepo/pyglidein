#!/bin/bash
# keep the perlmutter glidein fleet alive + tidy scratch.
#
# intended scrontab entry:
# #SCRON -q cron
# #SCRON -C cron
# #SCRON -A m1093
# #SCRON -t 00:30:00
# #SCRON -o $HOME/glideins/scron-%j.out
# #SCRON --open-mode=append
# 0 9 * * * $HOME/glideins/pyglidein2/helpers/submit_perlmutter.sh

# no accidental disk wipes
set -u

# scrontab sets various SLURM_* vars (esp. SLURM_MEM_PER_CPU=2048) that break child sbatch
unset ${!SLURM_@}

# clean up per-task scratch dirs (scratch autopurges at 8 weeks, way too slow for arrays)
find "$PSCRATCH/glideins" -mindepth 2 -maxdepth 2 -type d -mtime +3 -print0 \
    | xargs -0 -r -P 8 rm -rf

# clean up old glidein out/err files
find "$HOME/glideins/out" -type f -mtime +7 -delete

# top up each queue once it has nothing pending. running tasks don't count, we always want
# a backlog queued up. a submit may fail: the paid qos has no allocation left and overrun
# is only legal once it is gone, so both are expected outcomes.
pending=$(squeue -u "$USER" -h -t PENDING -o '%j')
for config in perlmutter_gpu_shared perlmutter_gpu_overrun perlmutter_cpu_overrun; do
    echo "$pending" | grep -q "$config" \
        || sbatch "$HOME/glideins/pyglidein2/configs/$config.slurm"
done

#!/bin/bash
# keep the perlmutter shared-gpu glidein fleet alive + tidy scratch.
# intended scrontab entry on the login pool (daily, times are UTC):
# 
# #SCRON -q cron
# #SCRON -C cron
# #SCRON -A m1093
# #SCRON -t 00:30:00
# #SCRON -o $HOME/glideins/glideins/scron-%j.out
# #SCRON --open-mode=append
# 0 9 * * * $HOME/glideins/pyglidein2/configs/helpers/submit_scrontab_perlmutter.sh

# no accidental disk wipes
set -u

# scrontab sets various SLURM_* vars (esp. SLURM_MEM_PER_CPU=2048) that break child sbatch
unset ${!SLURM_@}

# clean up per-task scratch dirs (scratch autopurges at 8 weeks, way too slow for arrays)
find "$PSCRATCH/glideins" -mindepth 2 -maxdepth 2 -type d -mtime +3 -print0 \
    | xargs -0 -r -P 8 rm -rf

# clean up old glidein out/err files
find "$HOME/glideins/out" -type f -mtime +7 -delete

# refresh the queue if there's no more pending jobs
# PENDING=$(squeue -u "$USER" -h -t PENDING -o '%j' | grep -c 'perlmutter_gpu_shared' || true)
# if [ "$PENDING" -lt 1 ]; then
#     echo "resubmitting perlmutter glidein array"
#     sbatch "$HOME/glideins/pyglidein2/configs/perlmutter_gpu_shared.slurm"
# fi

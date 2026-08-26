#!/bin/bash
# keep the harvard cpu + gpu glidein fleets alive + tidy scratch.
# intended scrontab entry (times are cluster-local; tune cadence as needed):
#
# #SCRON -t 01:00:00
# #SCRON -o /n/home13/ehobert/out/scron-%j.log
# #SCRON --open-mode=append
# 0 2 * * * /n/home13/ehobert/pyglidein2/configs/helpers/submit_scrontab_harvard.sh

# no accidental disk wipes
set -u
# scrontab sets various SLURM_* vars that may break child sbatch
unset ${!SLURM_@}

find /n/netscratch/arguelles_delgado_lab/Lab/glidein_prod/ -mindepth 1 -maxdepth 2 -type d -ctime +2 | xargs -P 8 rm -rf &
find /n/home13/ehobert/out/  -type f -ctime +2 | xargs -P 8 rm -rf &

# Have at least 2 jobs arrays in the queue at all times

if [ $(squeue --me -t PENDING | grep "gpu_reque" | wc -l) -le 2 ]; then
    echo "SUBMIT GPU"
    sbatch /n/home13/ehobert/pyglidein2/configs/harvard_gpu.slurm
fi

if [ $(squeue --me -t PENDING | grep "serial_re" | wc -l) -le 2 ]; then
    echo "SUBMIT CPU"
    sbatch /n/home13/ehobert/pyglidein2/configs/harvard_cpu.slurm
fi

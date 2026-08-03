#!/bin/bash

find /n/netscratch/arguelles_delgado_lab/Lab/IceCube/prod/ -maxdepth 1 -type d -ctime +2 | xargs -P 8 rm -rf &
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

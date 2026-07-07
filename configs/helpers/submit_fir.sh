#!/bin/bash

# Getting the slurm executables into PATH
export PATH=$PATH:/opt/software/slurm/bin/

if [ $(squeue -u briedel -t PENDING -p gpubase_bygpu_b3 -n glidein-mig-1slice | wc -l) -le 2 ]; then 
    echo "Submit 1 slice"
    sbatch /home/briedel/pyglidein2/configs/fir_gpu_mig.slurm
fi

if [ $(squeue -u briedel -t PENDING -p gpubase_bygpu_b3 -n glidein-mig-2slice | wc -l) -le 2 ]; then
    echo "Submit 2 slice"
    sbatch /home/briedel/pyglidein2/configs/fir_gpu_mig_2slices.slurm 
fi

if [ $(squeue -u briedel -t PENDING -p gpubase_bygpu_b3 -n glidein-mig-3slice | wc -l) -le 2 ]; then
    echo "Submit 3 Slice"
    sbatch /home/briedel/pyglidein2/configs/fir_gpu_mig_3slices.slurm
fi


if [ $(squeue -u briedel -t PENDING -p cpubase_bycore_b3 | wc -l) -le 2 ]; then
    echo "Submit CPU"
    sbatch /home/briedel/pyglidein2/configs/fir_cpu.slurm 
fi

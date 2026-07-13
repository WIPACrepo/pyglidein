#!/bin/bash

export WORK2=/work2/04799/tg840985/stampede3

counter=$(squeue -u $USER -p h100 | wc -l)

while [ $counter -le 4 ];
do
    sbatch /home1/04799/tg840985/pyglidein2/configs/stampede3_gpu.slurm
    counter=$(squeue -u $USER -p h100 | wc -l)
done


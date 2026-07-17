#!/bin/bash

export WORK2=/work2/04799/tg840985/stampede3

# at most we are allowed to submit 4 jobs into the h100 queue at a given time
max_submit=4

if [ $(squeue -u $USER -p h100 | grep "h100" | wc -l) -ge $max_submit ]; then
    exit
fi

for i in $(seq "1" "$max_submit"); do
    if [ $(squeue -u $USER -p h100 | wc -l) -ge $max_submit ]; then
        break
    fi
    sbatch /home1/04799/tg840985/pyglidein2/configs/stampede3_gpu.slurm
done

# counter=$(squeue -u $USER -p h100 | wc -l)

# while [ $counter -le 4 ];
# do
#     sbatch /home1/04799/tg840985/pyglidein2/configs/stampede3_gpu.slurm
#     counter=$(squeue -u $USER -p h100 | wc -l)
# done


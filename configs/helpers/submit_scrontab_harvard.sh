#!/bin/bash

find /n/netscratch/arguelles_delgado_lab/Lab/IceCube/prod/ -maxdepth 1 -type d -ctime +2 | xargs -P 8 rm -rf &
find /n/home00/briedel/out/  -type f -ctime +2 | xargs -P 8 rm -rf &

sbatch /n/home00/briedel/pyglidein2/configs/harvard.slurm

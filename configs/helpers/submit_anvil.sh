#!/bin/bash

find /anvil/scratch/x-briedel/pyglidein/ -type d -ctime +2 | xargs rm -rf &

find /home/x-briedel/logs/ -type f -ctime +5 | xargs rm -rf &

#for i in {1..32}; do 
	
sbatch  -q gpu /home/x-briedel/pyglidein2/configs/anvil_pyglidein2.slurm
# ; done

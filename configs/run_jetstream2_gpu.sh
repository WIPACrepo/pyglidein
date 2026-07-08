#!/bin/bash

unset LD_PRELOAD


export GLIDEIN_Site="IU Jetstream 2"
export SINGULARITY_BIN=apptainer
export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE3NjIzNzkzNjMsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6IjBiM2IzOGI5MzlkMGY0ZDM0ZDIwMDdjNWNlNjc1Mjk3Iiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0RBRU1PTiBjb25kb3I6XC9BRFZFUlRJU0VfU1RBUlREIGNvbmRvcjpcL0FEVkVSVElTRV9NQVNURVIiLCJzdWIiOiJweWdsaWRlaW5AaWNlY3ViZS53aXNjLmVkdSJ9.lM0ED5dEEWCEg1s5d4toNHk9vkbLapwgm6yx--OBcAE
export BASE_IMAGE=/home/rocky/osgvo-docker-pilot_25_cuda_11.8

export CUDA_VISIBLE_DEVICES=0
export CPUS=16
export MEMORY=60000
export GPUS=CUDA0
export GLIDEIN_Start_Extra="IceProdSite =?= \"long\""
# export USE_CVMFSEXEC=True
export ACCEPT_IDLE_MINUTES=60


counter=1

while [ $counter -le 5 ]
do 
    export SCRATCHDIR=$(mktemp -d)
    cd $SCRATCHDIR
    $HOME/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ~/pyglidein/pyglidein/glidein_start.sh #  1> $HOME/glidein.out 2> $HOME/glidein.err
    ((counter++))
done
# while true; do 
#     ~/pyglidein2/pyglidein/glidein_start.sh
# done

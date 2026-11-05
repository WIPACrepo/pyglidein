#!/bin/bash

unset LD_PRELOAD


export GLIDEIN_Site="IU Jetstream 2"
export SINGULARITY_BIN=apptainer
export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE3NjIzNzkzNjMsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6IjBiM2IzOGI5MzlkMGY0ZDM0ZDIwMDdjNWNlNjc1Mjk3Iiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0RBRU1PTiBjb25kb3I6XC9BRFZFUlRJU0VfU1RBUlREIGNvbmRvcjpcL0FEVkVSVElTRV9NQVNURVIiLCJzdWIiOiJweWdsaWRlaW5AaWNlY3ViZS53aXNjLmVkdSJ9.lM0ED5dEEWCEg1s5d4toNHk9vkbLapwgm6yx--OBcAE
export BASE_IMAGE=/home/rocky/ospool-ep_25-cuda_11_8_0-release.sif

export CUDA_VISIBLE_DEVICES=0
export CPUS=16
export MEMORY=60000
export GPUS=CUDA0
export GLIDEIN_Start_Extra="(TARGET.IceProdSite =?= \"long\" || TARGET.Owner =?= \"ice3simusr\" && regexp(\"Long\",TARGET.JobDurationCategory))"
# export USE_CVMFSEXEC=True
export ACCEPT_IDLE_MINUTES=600
export ACCEPT_JOBS_FOR_HOURS=3360


counter=1

while [ $counter -le 10 ]
do 
    export SCRATCHDIR=$(mktemp -d)
    cd $SCRATCHDIR
    # backup up last logs and removing previuous ones
    if [ -f "$HOME/glidein.out" ]; then
        mv -f $HOME/glidein.out $HOME/glidein_$counter.out
        rm -rf $HOME/glidein_$((counter - 1)).out
    fi
    if [ -f "$HOME/glidein.err" ]; then
        mv -f $HOME/glidein.err $HOME/glidein_$counter.err
	rm -rf $HOME/glidein_$((counter - 1)).err
    fi
    $HOME/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ~/pyglidein/pyglidein/glidein_start.sh > >(tee $HOME/glidein.out) 2> >(tee $HOME/glidein.err >&2)
    #  1> $HOME/glidein.out 2> $HOME/glidein.err
    ((counter++))
done
# while true; do 
#     ~/pyglidein2/pyglidein/glidein_start.sh
# done

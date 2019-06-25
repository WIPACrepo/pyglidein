#!/bin/sh

if [ -d /cvmfs/icecube.opensciencegrid.org ]; then
    
    singularity exec -C -B /tmp -B /cvmfs/icecube.opensciencegrid.org -B $PWD:/mnt --pwd /mnt /cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-el7-cuda10:latest /bin/sh glidein_start.sh

else
    singularity exec -C -B /tmp -B $PWD:/mnt --pwd /mnt dockerhub://opensciencegrid/osgvo-el7-cuda10 /bin/sh glidein_start.sh

fi

    


#!/bin/sh

export CUR_SHELL=`readlink "/proc/$$/exe"|awk -F'/' '{print $NF}'`
VAR=$(python <<EOF
import os
def set(k, v):
    if 'csh' in os.environ['CUR_SHELL']:
        print 'setenv '+k+' "'+v+'" ;'
    else:
        print 'export '+k+'="'+v+'" ;'
for k in os.environ:
  set('SINGULARITYENV_'+k, os.environ[k].replace('"','\\"'))
EOF
)
eval $VAR

export SINGULARITYENV_LD_LIBRARY_PATH=/.singularity.d/libs/

ARGS=""
if [ -d /etc/OpenCL/vendors ]; then

    ARGS="-B /etc/OpenCL/vendors"

fi

if [ -d /cvmfs/icecube.opensciencegrid.org ]; then

    ARGS="$ARGS -B /cvmfs"
fi

if [ "x$CONTAINER" = "x" ]; then

    if  [ -d /cvmfs/singularity.opensciencegrid.org ]; then

	CONTAINER=/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-el7-cuda10:latest
    else
    
	CONTAINER=docker://opensciencegrid/osgvo-el7-cuda10
    fi

fi

if [ "x$SINGULARITY_BIN" = "x" ]; then
    
    SINGULARITY_BIN="singularity"

fi
echo $SINGULARITY_BIN

$SINGULARITY_BIN exec --nv --cleanenv -C -B /tmp $ARGS -B $PWD:/mnt --pwd /mnt $CONTAINER /bin/sh glidein_start.sh

    


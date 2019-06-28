#!/bin/sh

# Run python script to parse out environment vars and
# sets them so that singularity can see them
# (this accounts for an issue with older versions of
# singularity where passing environment vars doesn't work properly)
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

# Configure bindings by checking if the resources exist
# then mounting them if they do
ARGS=""
if [ -d /etc/OpenCL/vendors ]; then

    ARGS="-B /etc/OpenCL/vendors"

fi

if [ -d /cvmfs/icecube.opensciencegrid.org ]; then

    ARGS="$ARGS -B /cvmfs"
fi

# Use the local OSG image if it exists; otherwise, pull from dockerhub
if [ "x$CONTAINER" = "x" ]; then

    if  [ -d /cvmfs/singularity.opensciencegrid.org ]; then

	CONTAINER=/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-el7-cuda10:latest
    else
    
	CONTAINER=docker://opensciencegrid/osgvo-el7-cuda10
    fi

fi

# Check if the SINGULARITY_BIN var has been set. If not, assume
# that singularity is in the PATH so just call it.
if [ "x$SINGULARITY_BIN" = "x" ]; then
    
    SINGULARITY_BIN="singularity"

fi
echo $SINGULARITY_BIN

# Execute the container with appropriate configurations, which
# will execute the glidein within.
$SINGULARITY_BIN exec --nv --cleanenv -C -B /tmp $ARGS -B $PWD:/mnt --pwd /mnt $CONTAINER /bin/sh glidein_start.sh

    


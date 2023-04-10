#!/bin/sh
set -e

# check for condor auth
if [ "x$TOKEN" = "x" ]; then
    echo "Condor IDTOKEN (\$TOKEN) is not set. Required for this! Performing seppuku!" 1>&2
    exit 1
fi

if [ "x$SINGULARITY_BIN" = "x" ]; then
    SINGULARITY_BIN="apptainer"
fi

if [ "x$SCRATCH_DIR" = "x" ]; then
    SCRATCH_DIR=$PWD
fi

if [ "x$CVMFS_BASE_DIR" = "x" ]; then
    CVMFS_BASE_DIR="/cvmfs"
fi

# Set this so that the accouting knows where the jobs ran
if [ "x$GLIDEIN_Site" = "x" ]; then
    export GLIDEIN_Site="IceCube"
fi

if [ "x$GLIDEIN_ResourceName" = "x" ]; then
    export GLIDEIN_ResourceName=$GLIDEIN_Site
fi

# This is an important setting limiting what jobs your glideins will accept.
# Anything here will get added to the START expression.
if [ "x$GLIDEIN_Start_Extra" = "x" ]; then
    export GLIDEIN_Start_Extra="True"
fi

# Set time of glidein
if [ "x$ACCEPT_JOBS_FOR_HOURS" = "x" ]; then
    export ACCEPT_JOBS_FOR_HOURS="24"
fi
if [ "x$ACCEPT_IDLE_MINUTES" = "x" ]; then
    export ACCEPT_IDLE_MINUTES="20"
fi
export SUPERVISORD_RESTART_POLICY="unexpected"

# customizations to talk to IceCube pool
export CONDOR_HOST="glidein-cm.icecube.wisc.edu"
export _condor_CONDOR_ADMIN="admin@icecube.wisc.edu"
export CCB_RANGE_LOW="9618"
export CCB_RANGE_HIGH="9618"

# set default container
export OSG_DEFAULT_CONTAINER_DISTRIBUTION="100%__opensciencegrid/osgvo-el7-cuda10:latest"

# specify resources, or let condor auto-detect them
if [ -z $CPUS ]; then
    CPUS=1
fi
if [ -z $MEMORY ]; then
    MEMORY=4000
fi
if [ -z $DISK ]; then
    DISK=8000000
fi
if [ -z $GPUS ]; then
   GPUS=0
fi 
export NUM_CPUS="$CPUS"
export MEMORY="$MEMORY" # in MB
export DISK="$DISK" # in KB

if [ "$GLIDEIN_Site" = "Anvil" ]; then
    export _condor_NETWORK_INTERFACE='172.18.*'
    export _condor_MASTER_DEBUG=D_HOSTNAME:2,D_ALWAYS:2
fi

# fix goto blas library threading
export GOTO_NUM_THREADS=1


# start the args with contain
ARGS="--contain"

# DONT USE THIS WITHOUT CGROUPS v2, so RHEL9...maybe?
# ARGS="$ARGS --cpus $CPUS --memory ${MEMORY}M"

# Add --nv for nvidia GPU jobs
if [ "x$CUDA_VISIBLE_DEVICES" != "x" ]; then
    ARGS="$ARGS --nv"
fi

# Need /dev/fuse to make sure we can singularity/apptainer works
# inside the container
ARGS_MOUNT="-B $SCRATCH_DIR:/pilot -B /dev/fuse -B $TMPDIR:$TMPDIR"
if [ -f /etc/OpenCL/vendors/*.icd ]; then
   ls -l /etc/OpenCL/vendors
   echo "ICD file present"
   ARGS_MOUNT="$ARGS_MOUNT -B /etc/OpenCL/vendors"
else
   echo "No ICD file present. Will not run with GPU support."
   export _condor_GPUS=0
fi

# Adding all the env vars

# DONT USE THIS WITHOUT CGROUPS v2, so RHEL9...maybe?
# ARGS="$ARGS --cpus $CPUS --memory ${MEMORY}M"
ARGS_ENV=""
if [ "x$SPECIAL_ENV" != "x"  ]; then
    ARGS_ENV="--env $SPECIAL_ENV"
fi
if [ "x$USE_CVMFSEXEC" != "x" ]; then
    ARGS_ENV="$ARGS_ENV,CVMFSEXEC_REPOS=oasis.opensciencegrid.org\ssingularity.opensciencegrid.org\sicecube.opensciencegrid.org"
else
    ARGS_MOUNT="$ARGS_MOUNT -B $CVMFS_BASE_DIR:/cvmfs"
fi

if [ "x$SPECIAL_ARGS" != "x" ]; then
    ARGS="$ARGS $SPECAL_ARGS"
fi

echo $ARGS_MOUNT
echo $ARGS_ENV
echo "JOB HOOK $CONTAINER_PILOT_USE_JOB_HOOK"
ARGS="$ARGS $ARGS_MOUNT $ARGS_ENV"

if [ "x$BASE_IMAGE" = "x" ]; then
    echo "Grapping default image: $PWD/osgvo-pilot.sif"
    BASE_IMAGE=$PWD/osgvo-pilot.sif
else
    echo "Using $BASE_IAGE"
fi

# export GLIDEIN_DEBUG_OUTPUT="DEBUG"
# export DEBUG_STARTUP=true

echo $TMPDIR 
echo $ARGS
echo "$SINGULARITY_BIN run $ARGS $BASE_IMAGE /bin/entrypoint.sh /usr/local/sbin/supervisord_startup.sh"

# The DISK and MEMORY variable dont get properly propagated right now so setting it by force  
export APPTAINERENV_MEMORY=$MEMORY
export APPTAINERENV_DISK=$DISK

# Allow CPU jobs to run in GPU slots 
export APPTAINERENV_ALLOW_CPUJOB_ON_GPUSLOT=true

# Getting environment in order for debugging
env -0 | sort -z | tr '\0' '\n'

$SINGULARITY_BIN run $ARGS $BASE_IMAGE /bin/entrypoint.sh /usr/local/sbin/supervisord_startup.sh

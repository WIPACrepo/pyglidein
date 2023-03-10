#!/bin/sh
set -e

# check for condor auth
if [ "x$TOKEN" = "x" ]; then
    echo "Condor $TOKEN is required" 1>&2
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
export NUM_CPUS="$CPUS"
#export MEMORY="$MEMORY" # in MB
export _condor_DISK="$DISK" # in KB

# fix goto blas library threading
export GOTO_NUM_THREADS=1


# start the args with contain
ARGS="--contain"

# DONT USE THIS WITHOUT CGROUPS v2, so RHEL9...maybe?
# ARGS="$ARGS --cpus $CPUS --memory ${MEMORY}M"

# Add --nv for GPU jobs
if [ "x$CUDA_VISIBLE_DEVICES" != "x" ]; then
    ARGS="$ARGS --nv"
fi

# Need /dev/fuse to make sure we can singularity/apptainer works
# inside the container
ARGS_MOUNT="-B $SCRATCH_DIR:/pilot -B /dev/fuse"
if [ -d /etc/OpenCL/vendors ]; then
   ARGS_MOUNT="$ARGS_MOUNT -B /etc/OpenCL/vendors"
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

ARGS="$ARGS $ARGS_MOUNT $ARGS_ENV"

BASE_IMAGE=""
if [ "x$BASE_IMAGE" = "x" ]; then
    BASE_IMAGE=$PWD/osgvo-pilot.sif
fi

echo $ARGS
echo "$SINGULARITY_BIN run $ARGS $BASE_IMAGE /bin/entrypoint.sh /usr/local/sbin/supervisord_startup.sh"
$SINGULARITY_BIN run $ARGS $BASE_IMAGE /bin/entrypoint.sh /usr/local/sbin/supervisord_startup.sh

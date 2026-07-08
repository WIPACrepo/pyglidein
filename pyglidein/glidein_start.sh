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
# export OSG_DEFAULT_CONTAINER_DISTRIBUTION="100%__opensciencegrid/osgvo-el7-cuda10:latest"
export OSG_DEFAULT_CONTAINER_DISTRIBUTION="100%__htc/rocky:8-cuda-11.0.3"
export APPTAINERENV_OSG_DEFAULT_CONTAINER_DISTRIBUTION=$OSG_DEFAULT_CONTAINER_DISTRIBUTION

export OSG_DEFAULT_CONTAINER_DISTRIBUTION_GPU="100%__opensciencegrid/osgvo-el7-cuda10:latest"
# "100%__wipac/pyglidein_el8_cuda11"
export APPTAINERENV_OSG_DEFAULT_CONTAINER_DISTRIBUTION_OSG=$OSG_DEFAULT_CONTAINER_DISTRIBUTION_GPU



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
if [ "x$GPUS" == "x" ]; then
   GPUS=0
fi
export NUM_CPUS="$CPUS"
export MEMORY="$MEMORY" # in MB
export DISK="$DISK" # in KB

if [ "$GLIDEIN_Site" = "Purdue Anvil" ]; then
    export _condor_NETWORK_INTERFACE='172.18.*'
    export _condor_MASTER_DEBUG=D_HOSTNAME:2,D_ALWAYS:2
fi

export GOTO_NUM_THREADS=1

# start the args with contain
ARGS="--contain"

# DONT USE THIS WITHOUT CGROUPS v2, so RHEL9...maybe?
# ARGS="$ARGS --cpus $CPUS --memory ${MEMORY}M"
#
#
#

if [ "x$TMPDIR" == "x" ]; then
    TMPDIR=/tmp
fi

if [ "$GLIDEIN_Site" = "Harvard" ]; then
    pyglidein_tmp_dir=$(mktemp -d -t $USER-XXXXXXXXXX)
else
    pyglidein_tmp_dir=$TMPDIR
fi

# inside the container
ARGS_MOUNT="-B $SCRATCH_DIR:/pilot -B /dev/fuse -B $pyglidein_tmp_dir:$TMPDIR"


if [ "x$NEED_CONDOR_EXTRA_ATTR" != "x" ]; then
    ARGS_MOUNT="$ARGS_MOUNT -B $SCRATCH_DIR/extra-attributes.cfg:/etc/osg/extra-attributes.cfg"
fi

echo "------glidein_start------"
if [ "x$GPUS" != "x0" ]; then
    echo "Trying to find OpenCL GPUs"
    if [ $(ls -l /etc/OpenCL/vendors/*.icd | wc -l) -gt 0 ]; then
        echo "ICD files present"
	ls -l /etc/OpenCL/vendors/*.icd
        ARGS_MOUNT="$ARGS_MOUNT -B /etc/OpenCL/vendors"
    else
        echo "No ICD file present. Will not run with GPU support."
        export _condor_GPUS=0
	break
    fi
    # Add --nv for nvidia GPU jobs
    if [ "x$CUDA_VISIBLE_DEVICES" != "x" ] || [ ! -z $CUDA_VISIBLE_DEVICES ]; then
        echo "CUDA_VISIBLE_DEVICES set to $CUDA_VISIBLE_DEVICES"
        ARGS="$ARGS --nv"
        if [ $(ls -l /etc/OpenCL/vendors/nvidia.icd | wc -l) == 0 ]; then
            echo "No NVIDIA ICD file present"
        fi
	if [ "$GLIDEIN_Site" = "Fir" ]; then
	    ARGS_MOUNT="$ARGS_MOUNT -B /usr/lib64/libnvidia-ml.so.1"
	fi
    # AMD GPUs
    elif [ $(ls -l /etc/OpenCL/vendors/amdocl64*.icd | wc -l) -gt 0 ]; then
        echo "AMD GPU, you say?"
	# removing the --contain from args
	# --rocm is kinda borked because the AMD depend on system libraries
	# so if you use a different OS than the base OS things can get 
	# wonky
        ARGS=""
    else
        echo "There are ICD files but not they are not NVIDIA or AMD. You in danger!" 
    fi
fi
# Adding all the env vars

# DONT USE THIS WITHOUT CGROUPS v2, so RHEL9...maybe?
# ARGS="$ARGS --cpus $CPUS --memory ${MEMORY}M"

ARGS_ENV="--env GLIDEIN_RANDOMIZE_NAME=true,OSG_PROJECT_NAME=IceCube,CPUS=$CPUS,NUM_CPUS=$NUM_CPUS,MEMORY=$MEMORY,DISK=$DISK"

# if [ "x$GLIDEIN_Start_Extra" != "x" ]; then
#     ARGS_ENV="$ARGS_ENV,GLIDEIN_Start_Extra=\"$GLIDEIN_Start_Extra\""
# fi

if [ "x$SPECIAL_ENV" != "x"  ]; then
    ARGS_ENV="$ARGS_ENV,$SPECIAL_ENV"
fi

if [ "x$USE_CVMFSEXEC" != "x" ]; then
    if [ "x$ARGS_ENV" != "x" ]; then
        ARGS_ENV="$ARGS_ENV,CVMFSEXEC_REPOS=oasis.opensciencegrid.org\ssingularity.opensciencegrid.org\sicecube.opensciencegrid.org\sara.opensciencegrid.org"
    else
        ARGS_ENV="$ARGS_ENV,CVMFSEXEC_REPOS=oasis.opensciencegrid.org\ssingularity.opensciencegrid.org\sicecube.opensciencegrid.org\sara.opensciencegrid.org"
    fi
    # /cvfmsexec has to writeable, so bindmound a directory
    ARGS_MOUNT="$ARGS_MOUNT -B $SCRATCH_DIR/cvmfsexec:/cvmfsexec"
else
    ARGS_MOUNT="$ARGS_MOUNT -B $CVMFS_BASE_DIR:/cvmfs"
fi

if [ "x$SPECIAL_ARGS" != "x" ]; then
    ARGS="$ARGS $SPECAL_ARGS"
fi

echo $ARGS
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

echo $TMPDIR 
echo $ARGS
echo "$SINGULARITY_BIN run $ARGS $BASE_IMAGE /usr/local/sbin/supervisord_startup.sh"

# --env doesn't work well here because of all the "". This works
export APPTAINERENV_GLIDEIN_Start_Extra=$GLIDEIN_Start_Extra


# Getting environment in order for debugging
env -0 | sort -z | tr '\0' '\n'

ulimit -n 5000

ulimit -n

$SINGULARITY_BIN run $ARGS $BASE_IMAGE /usr/local/sbin/supervisord_startup.sh

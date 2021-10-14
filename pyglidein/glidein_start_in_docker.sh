#!/bin/sh
set -e

# check for condor auth
if [ "x$TOKEN" = "x" ]; then
    echo "Condor $TOKEN is required" 1>&2
    exit 1
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

# specify resources, or let condor auto-detect them
if [ -z $CPUS ]; then
    CPUS=1
fi
if [ -z $MEMORY ]; then
    MEMORY=4000 # in MB
fi
if [ -z $DISK ]; then
    DISK=8000000 # in KB
fi

ARGS=""
if [ "x$CUDA_VISIBLE_DEVICES" != "x" ]; then
    ARGS="$ARGS --nv"
fi
if [ -d /etc/OpenCL/vendors ]; then
    ARGS="$ARGS -v /etc/OpenCL/vendors:/etc/OpenCL/vendors"
fi

docker run -it --rm --user osg \
        --security-opt seccomp=unconfined \
        --security-opt systempaths=unconfined \
        --security-opt no-new-privileges \
        -v /cvmfs:/cvmfs:shared -v $PWD:/pilot $ARGS \
        -e TOKEN=$TOKEN \
        -e GLIDEIN_Site=$GLIDEIN_SITE \
        -e GLIDEIN_ResourceName=$GLIDEIN_ResourceName \
        -e GLIDEIN_Start_Extra=$GLIDEIN_Start_Extra \
        -e ACCEPT_JOBS_FOR_HOURS=$ACCEPT_JOBS_FOR_HOURS \
        -e ACCEPT_IDLE_MINUTES=$ACCEPT_IDLE_MINUTES \
        -e SUPERVISORD_RESTART_POLICY="unexpected" \
        -e _condor_CONDOR_HOST="glidein-cm.icecube.wisc.edu" \
        -e _condor_CONDOR_ADMIN="admin@icecube.wisc.edu" \
        -e CCB_RANGE_LOW="9618" \
        -e CCB_RANGE_HIGH="9618" \
        -e OSG_DEFAULT_CONTAINER_DISTRIBUTION="100%__opensciencegrid/osgvo-el7:latest" \
        -e _condor_NUM_CPUS="$CPUS" \
        -e _condor_MEMORY="$MEMORY" \
        -e _condor_DISK="$DISK" \
        -e GOTO_NUM_THREADS="1" \
        docker://opensciencegrid/osgvo-docker-pilot:release

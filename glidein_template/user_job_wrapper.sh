#!/bin/bash

# This script is started just before the user job
# It is referenced by the USER_JOB_WRAPPER

export HOME=$PWD

# fix PATH and LD_LIBRARY_PATH
export PATH=$PATH:/usr/bin:/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib:/usr/lib/x86_64-linux-gnu:/lib64:/lib:/lib/x86_64-linux-gnu

# hide all GPUs unless job actually requested a GPU.
export CUDA_VISIBLE_DEVICES COMPUTE GPU_DEVICE_ORDINAL
gpu_dev=$(grep -e "^AssignedGPUs" $_CONDOR_MACHINE_AD | awk -F "= " "{print \$2}" | sed "s/CUDA//g" | sed "s/\"//g")
if [ -n "$gpu_dev" ]; then
  export CUDA_VISIBLE_DEVICES=$gpu_dev
  export COMPUTE=:0.$gpu_dev
  export GPU_DEVICE_ORDINAL=$gpu_dev
fi

GLIDEIN_DIR=$GLIDEIN_LOCAL_TMP_DIR
if [ ! -d $GLIDEIN_DIR ]; then
    GLIDEIN_DIR=$PWD
fi
JOB_WRAPPER="${GLIDEIN_DIR}/job_wrapper.sh"


# idbox TODO:
#  - run ssh_to_job shell under parrot idbox or disable ssh_to_job
#  - in real idbox mode, we must not allow any jobs to run without being wrapped by parrot
#  - do not run this script in user-controlled environment

# run a command with clean environment
safe() {
  /usr/bin/env -i "$@"
}

# Locate parrot.
GLIDEIN_PARROT="${GLIDEIN_DIR}/GLIDEIN_PARROT"

# Check whether we can already see cvmfs
USE_PARROT="y"
if [ ! -e $GLIDEIN_PARROT ]; then
    USE_PARROT="n"
fi
if [ -e /cvmfs/icecube.opensciencegrid.org/py2-v1 ]; then
    USE_PARROT="n"
fi

# As of parrot 3.4.0, parrot causes ssh_to_job to fail, so
# avoid using parrot when _CONDOR_JOB_PIDS is non-empty.
# (That's how we guess that this is an ssh_to_job session.)

if [ "$USE_PARROT" = "y" ] && [ -z "$_CONDOR_JOB_PIDS" ]; then

    # Workaround for GLOBUS_TCP_PORT_RANGE_STATE_FILE pointing to a file
    # we can't write to.  This breaks CMS CRAB 2.8.1 and prior.
    if [ "$GLOBUS_TCP_PORT_RANGE_STATE_FILE" != "" ] && ! [ -w "$GLOBUS_TCP_PORT_RANGE_STATE_FILE" ]; then
      unset GLOBUS_TCP_PORT_RANGE_STATE_FILE
    fi

    # point OSG_APP into cvmfs
    if [ "$CVMFS_OSG_APP" != "" ]; then
      export LOCAL_OSG_APP="$OSG_APP"
      export OSG_APP="$CVMFS_OSG_APP"
    fi

    # done messing with job environment; save it to a file for parrot/exec_job
    export -p > "${_CONDOR_SCRATCH_DIR}/parrot_job_env.sh"

    # only set the proxy for parrot/cvmfs
    if [ -z $http_proxy ]; then
        http_proxy=http://squid.icecube.wisc.edu:3128
    fi

    # Clense our environment before calling run_parrot, so the user cannot manipulate
    # run_parrot or parrot_run.  Preserve only the necessary variables.
    # We are calling run_parrot here, which calls parrot_run to run the job.
    if [ ! -e $JOB_WRAPPER ]; then
        exec /usr/bin/env -i \
           GLIDEIN_PARROT=${GLIDEIN_PARROT} \
           _CONDOR_SCRATCH_DIR=${_CONDOR_SCRATCH_DIR} \
           _CONDOR_SLOT=${_CONDOR_SLOT} \
           _CONDOR_JOB_PIDS=${_CONDOR_JOB_PIDS} \
           http_proxy=${http_proxy} \
        ${GLIDEIN_PARROT}/run_parrot "$@"
    else
        exec /usr/bin/env -i \
           GLIDEIN_PARROT=${GLIDEIN_PARROT} \
           _CONDOR_SCRATCH_DIR=${_CONDOR_SCRATCH_DIR} \
           _CONDOR_SLOT=${_CONDOR_SLOT} \
           _CONDOR_JOB_PIDS=${_CONDOR_JOB_PIDS} \
           http_proxy=${http_proxy} \
        ${GLIDEIN_PARROT}/run_parrot ${JOB_WRAPPER} "$@"
    fi

    # Note that since we exec the job above, wrappers that come after
    # this one are ignored.

else
    # fall through to next/default job wrapper
    if [ ! -e $JOB_WRAPPER ]; then
        exec "$@"
    else
        exec ${JOB_WRAPPER} "$@"
    fi
fi

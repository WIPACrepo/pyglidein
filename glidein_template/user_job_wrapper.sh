#!/bin/bash

# This script is started just before the user job
# It is referenced by the USER_JOB_WRAPPER

export HOME=$PWD

# fix PATH and LD_LIBRARY_PATH
export PATH=$PATH:/usr/bin:/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib:/usr/lib/x86_64-linux-gnu:/lib64:/lib:/lib/x86_64-linux-gnu

# hide all GPUs unless job actually requested a GPU.
# TODO: get AMD gpus working
export CUDA_VISIBLE_DEVICES COMPUTE GPU_DEVICE_ORDINAL
gpu_dev=$(echo $_CONDOR_AssignedGPUs | sed "s/CUDA//g" | sed "s/\"//g")
if [ -n "$gpu_dev" ]; then
  export CUDA_VISIBLE_DEVICES=$gpu_dev
  export COMPUTE=:0.$gpu_dev
  export GPU_DEVICE_ORDINAL=$gpu_dev
fi


# idbox TODO:
#  - run ssh_to_job shell under parrot idbox or disable ssh_to_job
#  - in real idbox mode, we must not allow any jobs to run without being wrapped by parrot
#  - do not run this script in user-controlled environment

# run a command with clean environment
safe() {
  /usr/bin/env -i "$@"
}

# Locate parrot.  We do not rely on any environment that the user can
# override, because we must avoid being manipulated by the user here.
GLIDEIN_PARROT="$_CONDOR_SCRATCH_DIR"
FORCE_PARROT=0
while [ 1 ]; do
    p=${GLIDEIN_PARROT%/*}
    if [ "$p" = "$GLIDEIN_PARROT" ]; then
        GLIDEIN_PARROT=""
    fi
    GLIDEIN_PARROT="$p"
    if [ -x "$GLIDEIN_PARROT/GLIDEIN_PARROT/run_parrot" ]; then
        GLIDEIN_PARROT="$GLIDEIN_PARROT/GLIDEIN_PARROT"
        if [ -e "$GLIDEIN_PARROT/FORCE_PARROT" ]; then
            FORCE_PARROT=1
        fi
        break
    fi
done

# Check whether we can already see cvmfs
USE_PARROT=1
if [ -e /cvmfs/icecube.opensciencegrid.org/py2-v1 ]; then
    USE_PARROT=0
fi

# As of parrot 3.4.0, parrot causes ssh_to_job to fail, so
# avoid using parrot when _CONDOR_JOB_PIDS is non-empty.
# (That's how we guess that this is an ssh_to_job session.)

if [ "$USE_PARROT" = 1 ] && ( "$FORCE_PARROT" = 1 ] || ( safe grep -q -i '^RequiresCVMFS *= *True' "${_CONDOR_JOB_AD}" && [ -z "$_CONDOR_JOB_PIDS" ] ) ); then

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


    # Clense our environment before calling run_parrot, so the user cannot manipulate
    # run_parrot or parrot_run.  Preserve only the necessary variables.
    # We are calling run_parrot here, which calls parrot_run to run the job.
    exec /usr/bin/env -i \
       GLIDEIN_PARROT=${GLIDEIN_PARROT} \
       _CONDOR_SCRATCH_DIR=${_CONDOR_SCRATCH_DIR} \
       _CONDOR_SLOT=${_CONDOR_SLOT} \
       _CONDOR_JOB_PIDS=${_CONDOR_JOB_PIDS} \
    ${GLIDEIN_PARROT}/run_parrot "$@"

    # Note that since we exec the job above, wrappers that come after
    # this one are ignored.
fi

# fall through to next/default job wrapper

# Condor job wrappers must replace its own image
exec "$@"

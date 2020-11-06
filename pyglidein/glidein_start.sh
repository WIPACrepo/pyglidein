#!/bin/sh

#DOMAIN="npx.icecube.wisc.edu"

if [ -z $GLIDEIN_NAME ]; then
    GLIDEIN_NAME=`uuid 2>/dev/null`
    if [ $? != 0 ]; then
        GLIDEIN_NAME=`python -c 'import uuid;print(uuid.uuid1())'`
    fi
fi

if [ -z $GLIDEIN_DIR ]; then
    GLIDEIN_DIR=${PWD}
fi
if [ -z $SITE ]; then
    SITE="WIPAC"
fi
if [ -z $ResourceName ]; then
    ResourceName=$SITE
fi
if [ -z $CLUSTER ]; then
    CLUSTER="glidein-simprod.icecube.wisc.edu"
fi
if [ -z $CACHE_DIR ]; then
    CACHE_DIR=$PWD
fi

if [ -z $WALLTIME ]; then
    # 20 hours
    WALLTIME=72000
fi
if [ -z $RETIRETIME ]; then
    # 20 minutes
    RETIRETIME=1200
fi
if [ ! $RETIRETIME -lt $WALLTIME ]; then
    echo "RETIRETIME ($RETIRETIME) must be less than WALLTIME ($WALLTIME)">&2
    exit 1
fi
if [ -z $NOCLAIMTIME ]; then
    # 20 minutes
    NOCLAIMTIME=1200
fi

if [ -z $CPUS ]; then
    CPUS=1
fi
if [ -z $GPUS ]; then
    GPUS=0
fi
if [ -z $MEMORY ]; then
    MEMORY=4000
fi
if [ -z $DISK ]; then
    DISK=8000000
fi
if [ -z $PRESIGNED_GET_URL ]; then
  PRESIGNED_GET_URL="none"
fi
# CVMFS is always true with parrot
CVMFS="True"

# GPU type detection
GPU_NAMES=""
if [ $GPUS != 0 ]; then
    if command -v nvidia-smi >/dev/null; then
        if [ "$GPUS" = "all" ]; then
            GPU_NAMES=$(nvidia-smi --query-gpu=name --format=csv,noheader|sed ':a;N;$!ba;s/\n/,/g');
        else
            GPU2=$(echo "$GPUS"|sed 's/CUDA//g'|sed 's/OCL//g');
            GPU_NAMES=$(nvidia-smi --query-gpu=name --format=csv,noheader --id=$GPU2|sed ':a;N;$!ba;s/\n/,/g');
        fi
    else
        # GPUs might exist but nvidia-smi is not available. re-set $GPUS
        GPUS=0
    fi
fi

##
# Done with config
##

export GOTO_NUM_THREADS=1

# assume you are already in a scratch directory
mkdir -p glidein
cd glidein

export _condor_OASIS_CVMFS_Exists="${CVMFS}"
export _condor_ICECUBE_CVMFS_Exists="${CVMFS}"
export _condor_HAS_CVMFS_icecube_opensciencegrid_org="${CVMFS}"

export _condor_MASTER_NAME="$GLIDEIN_NAME"
export _condor_STARTD_NAME="$GLIDEIN_NAME"
export _condor_CONDOR_HOST="$CLUSTER"
if [ "$CLUSTER" = "glidein-simprod.icecube.wisc.edu" ]; then
	export _condor_COLLECTOR_HOST="${CLUSTER}:9618?sock=sub-collector-\$RANDOM_CHOICE(1,2,3,4,5,6,7,8,9)"
	export _condor_CCB_ADDRESS="${CLUSTER}:9618?sock=sub-collector-\$RANDOM_CHOICE(1,2,3,4,5,6,7,8,9)"
else
	export _condor_COLLECTOR_HOST="${CLUSTER}:9618?sock=collector"
	export _condor_CCB_ADDRESS="${CLUSTER}:9618?sock=collector"
fi
export _condor_ALLOW_CONFIG="$CLUSTER"
export _condor_ENABLE_RUNTIME_CONFIG="True"
export _condor_SETTABLE_ATTRS_CONFIG="*"
export _condor_USE_SHARED_PORT="False";
export _condor_GLIDEIN_Site="\"${SITE}\""
export _condor_GLIDEIN_SiteResource="\"${ResourceName}\"";
export _condor_GLIDEIN_HOST="$CLUSTER"
export _condor_GLIDEIN_Max_Walltime=${WALLTIME};
export _condor_GLIDEIN_Job_Max_Time=${WALLTIME};
export _condor_CLAIM_WORKLIFE=${WALLTIME};
export _condor_PYGLIDEIN_TIME_TO_LIVE="${WALLTIME} - ${RETIRETIME} - MonitorSelfAge";
export _condor_STARTD_NOCLAIM_SHUTDOWN="ifThenElse(ifThenElse(isUndefined(NumDynamicSlots),False,NumDynamicSlots > 0), ${WALLTIME} - MonitorSelfAge, ${NOCLAIMTIME})";
export _condor_MaxJobRetirementTime="ifThenElse(PYGLIDEIN_TIME_TO_LIVE < 0, ${RETIRETIME}, PYGLIDEIN_TIME_TO_LIVE)"
export _condor_SLOT1_RetirementTime="ifThenElse(MonitorSelfAge + ${RETIRETIME} > ${WALLTIME}, ${RETIRETIME}, ${WALLTIME} - ${RETIRETIME} - MonitorSelfAge)";
export _condor_DAEMON_SHUTDOWN="ifThenElse(MonitorSelfAge > ${WALLTIME}, True, False)";
export _condor_NOT_RESPONDING_TIMEOUT="${NOCLAIMTIME}*2";
export _condor_POLLING_INTERVAL="60";
export _condor_HISTORY="UNDEFINED";
export _condor_SLOTS_CONNECTED_TO_CONSOLE="0";
export _condor_SLOTS_CONNECTED_TO_KEYBOARD="0";
export _condor_RUNBENCHMARKS="False";
export _condor_USE_PROCESS_GROUPS="False"
export _condor_CONDOR_ADMIN="david.schultz@icecube.wisc.edu"
export _condor_NUM_CPUS=${CPUS};
export _condor_MEMORY=${MEMORY};
export _condor_DISK=${DISK};
export _condor_GPU_NAMES="\"${GPU_NAMES}\"";
export _condor_MACHINE_RESOURCE_NAMES="gpus";
export _condor_MACHINE_RESOURCE_GPUs=${GPUS};
export _condor_SLOT_TYPE_1="100%"
export _condor_NUM_SLOTS_TYPE_1=1
export _condor_SLOT_TYPE_1_PARTITIONABLE="True"
#export _condor_SLOT_TYPE_1_CONSUMPTION_POLICY="True"
#export _condor_SLOT_TYPE_1_CONSUMPTION_GPUs="quantize(ifThenElse(target.RequestGpus =!= undefined,target.RequestGpus,0),{0})";
export _condor_SLOT_WEIGHT="Cpus";
export _condor_SLOT1_STARTD_ATTRS="OASIS_CVMFS_Exists ICECUBE_CVMFS_Exists HAS_CVMFS_icecube_opensciencegrid_org GLIDEIN_Site GLIDEIN_SiteResource GLIDEIN_Max_Walltime GPU_NAMES PRESIGNED_GET_URL PYGLIDEIN_PARROT PYGLIDEIN_TIME_TO_LIVE"
export _condor_STARTER_JOB_ENVIRONMENT="\"GLIDEIN_Site=${SITE} GLIDEIN_SiteResource=${ResourceName} GLIDEIN_LOCAL_TMP_DIR=${PWD} GOTO_NUM_THREADS=1\"";
export _condor_START="((GPUs > 0) ? (isUndefined(RequestGPUs) ? FALSE : (RequestGPUs > 0)) : TRUE)";
if [ "x$GROUP" = "x" ]; then
    export _condor_RANK="(isUndefined(RequestGPUs) ? 0 : (RequestGPUs * 10000)) + RequestMemory";
else
    export _condor_RANK="(isUndefined(RequestGPUs) ? 0 : (RequestGPUs * 10000)) + RequestMemory + ((Affiliation =?= \"${GROUP}\") ? 100000 : 0)";
fi

export _condor_UID_DOMAIN=""
#export _condor_FILESYSTEM_DOMAIN=${DOMAIN}
export _condor_MAIL=/bin/mail;
export _condor_IS_OWNER="False"
export _campusfactory_wntmp=$PWD
export _condor_UPDATE_COLLECTOR_WITH_TCP="True"
export _campusfactory_CAMPUSFACTORY_LOCATION=$PWD
export _condor_USER_JOB_WRAPPER=$PWD/user_job_wrapper.sh
export _condor_PRESIGNED_GET_URL="\"$PRESIGNED_GET_URL\""

# STARTD CRON
if [ -z $DISABLE_STARTD_CHECKS ]; then
  export _condor_STARTD_CRON_JOBLIST='clsimgpu cvmfs gridftp'
  export _condor_STARTD_CRON_CLSIMGPU_MODE='OneShot'
  export _condor_STARTD_CRON_CLSIMGPU_RECONFIG_RERUN='True'
  export _condor_STARTD_CRON_CLSIMGPU_EXECUTABLE='../../post_cvmfs.sh'
  export _condor_STARTD_CRON_CLSIMGPU_ARGS='../../clsim_gpu_test.py -n 1'
  export _condor_STARTD_CRON_CVMFS_MODE='OneShot'
  export _condor_STARTD_CRON_CVMFS_RECONFIG_RERUN='True'
  export _condor_STARTD_CRON_CVMFS_EXECUTABLE='../../pre_cvmfs.sh'
  export _condor_STARTD_CRON_CVMFS_ARGS='../../cvmfs_test.py /cvmfs/icecube.opensciencegrid.org/py2-v1/RHEL_6_x86_64/bin/globus-url-copy 36648bd8463ecfc7464042628905d490'
  export _condor_STARTD_CRON_GRIDFTP_MODE='OneShot'
  export _condor_STARTD_CRON_GRIDFTP_RECONFIG_RERUN='True'
  export _condor_STARTD_CRON_GRIDFTP_EXECUTABLE='../../post_cvmfs.sh'
  export _condor_STARTD_CRON_GRIDFTP_ARGS='../../gridftp_test.py gridftp.icecube.wisc.edu 2811'
fi


# detect CVMFS and get the OS type
OS_ARCH="RHEL_6_x86_64"
. $GLIDEIN_DIR/os_arch.sh

# disable proxy for prod-exe
export no_proxy=prod-exe.icecube.wisc.edu

if [ -e $GLIDEIN_DIR/glidein.tar.gz ]; then
  tar xzf $GLIDEIN_DIR/glidein.tar.gz
else
  if wget -nv http://prod-exe.icecube.wisc.edu/glidein-$OS_ARCH.tar.gz ; then
    tar xzf glidein-$OS_ARCH.tar.gz
  else
    wget -nv http://prod-exe.icecube.wisc.edu/glidein.tar.gz
    tar xzf glidein.tar.gz
  fi
fi

# check the parrot tmp
if [ "x${GLIDEIN_PARROT_TMP}" != "x" ]; then
    if [ ! -d ${GLIDEIN_PARROT_TMP} ]; then
        mkdir ${GLIDEIN_PARROT_TMP}
    fi
fi

# test for cvmfs
CVMFS="false"
if [ -e /cvmfs/icecube.opensciencegrid.org/py2-v1/setup.sh ]; then
    CVMFS="true"
    export _condor_PYGLIDEIN_PARROT="False"
else
    # test parrot
    export _condor_PYGLIDEIN_PARROT="True"
    if [ -z $http_proxy ]; then
        http_proxy=http://squid.icecube.wisc.edu:3128
    fi
    # Setup startd cron scripts for parrot
    export _condor_STARTD_CRON_CLSIMGPU_EXECUTABLE='../../glidein/GLIDEIN_PARROT/run_parrot'
    export _condor_STARTD_CRON_CLSIMGPU_ARGS='../../post_cvmfs.sh ../../clsim_gpu_test.py -n 1'
    export _condor_STARTD_CRON_CLSIMGPU_ENV="\"GLIDEIN_PARROT_TMP=${GLIDEIN_PARROT_TMP} GLIDEIN_PARROT=${PWD}/GLIDEIN_PARROT _CONDOR_SCRATCH_DIR=${PWD} http_proxy=${http_proxy}\""
    export _condor_STARTD_CRON_CVMFS_EXECUTABLE='../../glidein/GLIDEIN_PARROT/run_parrot'
    export _condor_STARTD_CRON_CVMFS_ARGS='../../pre_cvmfs.sh ../../cvmfs_test.py /cvmfs/icecube.opensciencegrid.org/py2-v1/RHEL_6_x86_64/bin/globus-url-copy 36648bd8463ecfc7464042628905d490'
    export _condor_STARTD_CRON_CVMFS_ENV="\"GLIDEIN_PARROT_TMP=${GLIDEIN_PARROT_TMP} GLIDEIN_PARROT=${PWD}/GLIDEIN_PARROT _CONDOR_SCRATCH_DIR=${PWD} http_proxy=${http_proxy}\""
    export _condor_STARTD_CRON_GRIDFTP_EXECUTABLE='../../glidein/GLIDEIN_PARROT/run_parrot'
    export _condor_STARTD_CRON_GRIDFTP_ARGS='../../post_cvmfs.sh ../../gridftp_test.py gridftp.icecube.wisc.edu 2811'
    export _condor_STARTD_CRON_GRIDFTP_ENV="\"GLIDEIN_PARROT_TMP=${GLIDEIN_PARROT_TMP} GLIDEIN_PARROT=${PWD}/GLIDEIN_PARROT _CONDOR_SCRATCH_DIR=${PWD} http_proxy=${http_proxy}\""
    cat > $PWD/parrot_job_env.sh << "EOF"
#!/bin/sh
$@
EOF
    chmod +x $PWD/parrot_job_env.sh
    if /usr/bin/env -i \
       GLIDEIN_PARROT_TMP=${GLIDEIN_PARROT_TMP} \
       GLIDEIN_PARROT=${PWD}/GLIDEIN_PARROT \
       _CONDOR_SCRATCH_DIR=${PWD} \
       _CONDOR_SLOT="" \
       http_proxy=${http_proxy} \
       GLIDEIN_PARROT/run_parrot ls /cvmfs/icecube.opensciencegrid.org/py2-v1/setup.sh >/dev/null 2>/dev/null ; then
        CVMFS="true"
    fi
fi
if [ "$CVMFS" = "false" ]; then
    echo "CVMFS missing. This glidein won't work, so kill."
    exit 1
fi

export campus_factory_dir=$PWD

export CONDOR_CONFIG=$PWD/glidein_condor_config
export _condor_LOCAL_DIR=$PWD
export _condor_SBIN=$PWD/glideinExec/sbin
export _condor_LIB=$PWD/glideinExec/lib
export _condor_LOG=$PWD/log.${GLIDEIN_NAME}
export _condor_EXECUTE=$PWD/execute.${GLIDEIN_NAME}
export _condor_SPOOL=$PWD/spool.${GLIDEIN_NAME}

if [ ! -d $PWD/log.$GLIDEIN_NAME ]; then
    mkdir $PWD/log.$GLIDEIN_NAME
fi

if [ ! -d $PWD/execute.$GLIDEIN_NAME ]; then
    mkdir $PWD/execute.$GLIDEIN_NAME
fi

if [ ! -d $PWD/spool.$GLIDEIN_NAME ]; then
    mkdir $PWD/spool.$GLIDEIN_NAME
fi


if [ -n "$CVMFS_JOB_WRAPPER" ]; then
    # make a job wrapper
    cat > $PWD/job_wrapper.sh << "EOF"
#!/bin/sh
eval `/cvmfs/icecube.opensciencegrid.org/py2-v1/setup.sh`
$@
EOF
    chmod +x $PWD/job_wrapper.sh
fi

export PATH=$PATH:$_condor_SBIN:$PWD/glideinExec/bin
export LD_LIBRARY_PATH=$_condor_LIB:$_condor_LIB/condor:$LD_LIBRARY_PATH

# run condor
trap 'kill -TERM $PID; if [ -n $PID_LOG_SHIPPER ]; then kill -TERM $PID_LOG_SHIPPER; fi' SIGTERM SIGINT
glideinExec/sbin/condor_master -f -r $(((${WALLTIME}-${RETIRETIME})/60)) &
PID=$!

# starting log_shipper
if [ -n "$PRESIGNED_PUT_URL" ]
  then
    ../log_shipper.sh ${PRESIGNED_PUT_URL} &
    PID_LOG_SHIPPER=$!
else
    (sleep 20 && tail -f -n +1 log.*/*Log) &
    PID_LOG_SHIPPER=$!
fi

wait $PID
trap - SIGTERM SIGKILL

if [ -n "$PRESIGNED_PUT_URL" ]
  then
    tar czf logs.tar.gz log.*
    unset http_proxy
    curl --upload-file logs.tar.gz ${PRESIGNED_PUT_URL}
fi

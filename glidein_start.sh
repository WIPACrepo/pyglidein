#!/bin/sh

#DOMAIN="npx.icecube.wisc.edu"

if [ -z $GLIDEIN_DIR ]; then
    GLIDEIN_DIR=${PWD}
fi
if [ -z $SITE ]; then
    SITE="WIPAC"
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
# CVMFS is always true with parrot
CVMFS="True"

# GPU type detection
GPU_NAMES=""
if [ $GPUS != 0 ]; then
    if command -v nvidia-smi >/dev/null; then
        GPU2=$(echo "$GPUS"|sed 's/CUDA//g');
        GPU_NAMES=$(nvidia-smi --query-gpu=name --format=csv,noheader --id=$GPU2);
    fi
fi


##
# Done with config
##

export GOTO_NUM_THREADS=1

# assume you are already in a scratch directory
mkdir glidein
cd glidein

export _condor_OASIS_CVMFS_Exists="${CVMFS}"
export _condor_ICECUBE_CVMFS_Exists="${CVMFS}"
export _condor_HAS_CVMFS_icecube_opensciencegrid_org="${CVMFS}"

export _condor_CONDOR_HOST="$CLUSTER"
if [ "$CLUSTER" = "glidein-simprod.icecube.wisc.edu" ]; then
	export _condor_COLLECTOR_HOST="${CLUSTER}:9618?sock=sub-collector-\$RANDOM_CHOICE(1,2,3,4,5)"
	export _condor_CCB_ADDRESS="${CLUSTER}:9618?sock=sub-collector-\$RANDOM_CHOICE(1,2,3,4,5)"
else
	export _condor_COLLECTOR_HOST="${CLUSTER}:9618?sock=collector"
	export _condor_CCB_ADDRESS="${CLUSTER}:9618?sock=collector"
fi
export _condor_ALLOW_CONFIG="$CLUSTER"
export _condor_ENABLE_RUNTIME_CONFIG="True"
export _condor_SETTABLE_ATTRS_CONFIG="*"
export _condor_GLIDEIN_Site="\"${SITE}\""
export _condor_GLIDEIN_HOST="$CLUSTER"
export _condor_GLIDEIN_Max_Walltime=${WALLTIME};
export _condor_GLIDEIN_Job_Max_Time=${WALLTIME};
export _condor_CLAIM_WORKLIFE=${WALLTIME};
export _condor_TimeToLive="${WALLTIME} - MonitorSelfAge";
export _condor_STARTD_NOCLAIM_SHUTDOWN="ifThenElse(ifThenElse(isUndefined(NumDynamicSlots),False,NumDynamicSlots > 0), ${WALLTIME} - MonitorSelfAge, ${NOCLAIMTIME})";
export _condor_MaxJobRetirementTime=${WALLTIME}
export _condor_SLOT1_RetirementTime="ifThenElse(MonitorSelfAge + ${RETIRETIME} > ${WALLTIME}, ${RETIRETIME}, MonitorSelfAge + ${RETIRETIME} - ${WALLTIME})";
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
export _condor_SLOT1_STARTD_ATTRS="OASIS_CVMFS_Exists ICECUBE_CVMFS_Exists HAS_CVMFS_icecube_opensciencegrid_org GLIDEIN_Site GLIDEIN_Max_Walltime GPU_NAMES"
export _condor_STARTER_JOB_ENVIRONMENT="\"GLIDEIN_Site=${SITE} GLIDEIN_LOCAL_TMP_DIR=${PWD} GOTO_NUM_THREADS=1\"";
export _condor_START="((GPUs > 0) ? (isUndefined(RequestGPUs) ? FALSE : (RequestGPUs > 0)) : TRUE)";
export _condor_RANK="(isUndefined(RequestGPUs) ? 0 : (RequestGPUs * 10000)) + RequestMemory";
export _condor_UID_DOMAIN=""
#export _condor_FILESYSTEM_DOMAIN=${DOMAIN}
export _condor_MAIL=/bin/mail;
export _condor_IS_OWNER="False"
export _campusfactory_wntmp=$PWD
export _condor_UPDATE_COLLECTOR_WITH_TCP="True"
export _campusfactory_CAMPUSFACTORY_LOCATION=$PWD
export _condor_USER_JOB_WRAPPER=$PWD/user_job_wrapper.sh

# detect CVMFS and get the OS type
OS_ARCH="RHEL_6_x86_64"
. $GLIDEIN_DIR/os_arch.sh

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

# test for cvmfs
CVMFS="false"
if [ -e /cvmfs/icecube.opensciencegrid.org/py2-v1/setup.sh ]; then
    CVMFS="true"
else
    # test parrot
    if [ -z $http_proxy ]; then
        http_proxy=http://squid.icecube.wisc.edu:3128
    fi
    cat > $PWD/parrot_job_env.sh << "EOF"
#!/bin/sh
$@
EOF
    chmod +x $PWD/parrot_job_env.sh
    if /usr/bin/env -i \
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
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$_condor_LIB

# run condor
exec glideinExec/sbin/condor_master -dyn -f -r 1200

# clean up after ourselves
cd ..
rm -rf glidein

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
    # 14 hours
    WALLTIME=50400
fi
if [ -z $RETIRETIME ]; then
    # 20 minutes
    RETIRETIME=1200
fi
if [ -z $NOCLAIMTIME ]; then
    # 10 minutes
    NOCLAIMTIME=600
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

export _condor_CONDOR_HOST="$CLUSTER"
export _condor_COLLECTOR_HOST="${CLUSTER}:9618?sock=collector"
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
export _condor_HISTORY="UNDEFINED";
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
export _condor_SLOT_TYPE_1_CONSUMPTION_POLICY="True"
export _condor_SLOT_TYPE_1_CONSUMPTION_GPUs="quantize(ifThenElse(target.RequestGpus =!= undefined,target.RequestGpus,0),{0})";
export _condor_SLOT_WEIGHT="Cpus";
export _condor_SLOT1_STARTD_ATTRS="OASIS_CVMFS_Exists ICECUBE_CVMFS_Exists GLIDEIN_Site GLIDEIN_Max_Walltime GPU_NAMES"
export _condor_STARTER_JOB_ENVIRONMENT="\"GLIDEIN_Site=${SITE} GLIDEIN_LOCAL_TMP_DIR=${PWD} GOTO_NUM_THREADS=1\"";
export _condor_START="ifThenElse(ifThenElse(MY.GPUs =!= undefined,MY.GPUs,0) > 0,ifThenElse(TARGET.RequestGPUs =!= undefined,TARGET.RequestGPUs,0) > 0,TRUE)";
export _condor_UID_DOMAIN=""
#export _condor_FILESYSTEM_DOMAIN=${DOMAIN}
export _condor_MAIL=/bin/mail;
export _condor_IS_OWNER="False"
export _campusfactory_wntmp=$PWD
export _condor_CCB_ADDRESS="${CLUSTER}:9618?sock=collector"
#export _condor_PRIVATE_NETWORK_NAME=${DOMAIN}
export _condor_UPDATE_COLLECTOR_WITH_TCP="True"
export _campusfactory_CAMPUSFACTORY_LOCATION=$PWD
export _condor_USER_JOB_WRAPPER=$PWD/user_job_wrapper.sh

if [ ! -e $GLIDEIN_DIR/glidein.tar.gz ]; then
  wget -nv http://prod-exe.icecube.wisc.edu/glidein.tar.gz
  GLIDEIN_DIR=$PWD
fi
tar xzf $GLIDEIN_DIR/glidein.tar.gz

export campus_factory_dir=$PWD

export CONDOR_CONFIG=$PWD/glidein_condor_config
export _condor_LOCAL_DIR=$PWD
export _condor_SBIN=$PWD/glideinExec/sbin
export _condor_LIB=$PWD/glideinExec/lib

# make a job wrapper
cat > $PWD/job_wrapper.sh << "EOF"
#!/bin/sh
eval `/cvmfs/icecube.opensciencegrid.org/py2-v1/setup.sh`
$@
EOF
chmod +x $PWD/job_wrapper.sh

export PATH=$PATH:$_condor_SBIN:$PWD/glideinExec/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$_condor_LIB

# run condor
exec glideinExec/sbin/condor_master -dyn -f -r 1200

# clean up after ourselves
cd ..
rm -rf glidein

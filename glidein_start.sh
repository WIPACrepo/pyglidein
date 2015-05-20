#!/bin/sh

# assume you are already in a scratch directory

DOMAIN="npx.icecube.wisc.edu"
GLIDEIN_DIR=${PWD}

if [ -z "$CPUS" ]; then
CPUS=1
fi
if [ -z "$MEMORY" ]; then
MEMORY=4000
fi
if [ -z "$DISK" ]; then
DISK=8000000
fi
if [ -z "$CVMFS" ]; then
CVMFS="False"
fi

export GOTO_NUM_THREADS=1

BOSCO_CLUSTER=bosco-3.icecube.wisc.edu

# 14 hours
WALLTIME=50400
RETIRETIME=50400
NOCLAIMTIME=3600

mkdir glidein
cd glidein

export _condor_OASIS_CVMFS_Exists="${CVMFS}"

export _condor_CONDOR_HOST="$BOSCO_CLUSTER"
export _condor_COLLECTOR_HOST="${BOSCO_CLUSTER}:11000?sock=collector"
export _condor_GLIDEIN_HOST="$BOSCO_CLUSTER"
export _condor_GLIDEIN_Max_Walltime=${WALLTIME};
export _condor_GLIDEIN_Job_Max_Time=${WALLTIME};
export _condor_CLAIM_WORKLIFE=${WALLTIME};
export _condor_TimeToLive=${WALLTIME};
export _condor_SHUTDOWN_GRACEFUL_TIMEOUT=${WALLTIME};
export _condor_STARTD_NOCLAIM_SHUTDOWN=${NOCLAIMTIME};
export _condor_MaxJobRetirementTime=${RETIRETIME};
export _condor_CONDOR_ADMIN="david.schultz@icecube.wisc.edu"
export _condor_NUM_CPUS=${CPUS};
export _condor_MEMORY=${MEMORY};
export _condor_DISK=${DISK};
export _condor_SLOT_TYPE_1="100%"
export _condor_NUM_SLOTS_TYPE_1=1
export _condor_SLOT_TYPE_1_PARTITIONABLE="True"
export _condor_SLOT1_STARTD_ATTRS="OASIS_CVMFS_Exists"
export _condor_UID_DOMAIN=""
export _condor_FILESYSTEM_DOMAIN=${DOMAIN}
export _condor_MAIL=/bin/mail;
export _campusfactory_wntmp=$PWD
export _condor_GLIDEIN_Site="WIPAC"
export _condor_BOSCOCluster="WIPAC"
export _condor_CCB_ADDRESS="${BOSCO_CLUSTER}:11000?sock=collector"
export _condor_PRIVATE_NETWORK_NAME=${DOMAIN}
export _condor_UPDATE_COLLECTOR_WITH_TCP="True"
export _campusfactory_CAMPUSFACTORY_LOCATION=$PWD

if [ ! -e $GLIDEIN_DIR/glidein.tar.gz ]; then
  wget -nv http://prod-exe.icecube.wisc.edu/glidein.tar.gz
  GLIDEIN_DIR=$PWD
fi
tar xzf $GLIDEIN_DIR/glidein.tar.gz

export campus_factory_dir=$PWD

export CONDOR_CONFIG=$PWD/glidein_condor_config
export _condor_LOCAL_DIR=$PWD
export _condor_SBIN=$PWD/glideinExec
export _condor_LIB=$PWD/glideinExec

export LD_LIBRARY_PATH=$_condor_LIB


if [ -e $PWD/user_job_wrapper.sh ]; then
  export _condor_USER_JOB_WRAPPER=$PWD/user_job_wrapper.sh
fi

./glideinExec/glidein_startup -dyn -f -r 1200

cd ..

rm -rf glidein

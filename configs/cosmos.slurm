#!/bin/bash
#SBATCH --nodes=1
#SBATCH --job-name=glidein
#SBATCH --time=01:00:00      # hh:mm:ss for the job
#SBATCH --array=1-2 # 7500
#SBATCH -o /cosmos/vast/scratch/briedel/logs/%A.%a.out  # File to which STDOUT will be written, %j inserts jobid
#SBATCH -e /cosmos/vast/scratch/briedel/logs/%A.%a.err  # File to which STDERR will be written, %j inserts jobid


module purge

echo `date`
echo $HOSTNAME

export MEMORY=492000 # 11600
# export WALLTIME=86400
export ACCEPT_JOBS_FOR_HOURS=24
export CPUS=24
export DISK=81920000000
export GPUS="GPU0, GPU1, GPU2, GPU3"
export GLIDEIN_Site="SDSC Cosmos"

GLIDEIN_LOC=/cosmos/nfs/home/briedel/pyglidein2/pyglidein

LOCAL_DIR=//cosmos/vast/scratch/briedel/tmp/${SLURM_JOBID}/${SLURM_ARRAY_TASK_ID}
CVMFSEXEC_DIR=/cosmos/vast/scratch/briedel/cvmfsexec_mine/


mkdir -p ${LOCAL_DIR}
cd $LOCAL_DIR
cp -a $CVMFSEXEC_DIR . 

ls ${LOCAL_DIR}/cvmfsexec_mine
echo "---"

mkdir glidein
cd glidein
echo $PWD
# cp /u/riedel1/osgvo-pilot.sif .
# cp /projects/bbfw/riedel1/osgvo-docker-pilot-wip-binds.sif ./osgvo-pilot.sif
cp $GLIDEIN_LOC/glidein_start.sh .


export TOKEN=eyJhbGciOiJIUzI1NiIsImtpZCI6IlBPT0wifQ.eyJpYXQiOjE2NzgzODIwOTIsImlzcyI6ImdsaWRlaW4tY20uaWNlY3ViZS53aXNjLmVkdSIsImp0aSI6ImI4NjRmOTY5ZGRjN2ZkMjU1MDk2YWU0ZTZjZGE0YWNjIiwic2NvcGUiOiJjb25kb3I6XC9SRUFEIGNvbmRvcjpcL1dSSVRFIGNvbmRvcjpcL0FEVkVSVElTRV9TVEFSVEQgY29uZG9yOlwvQURWRVJUSVNFX01BU1RFUiIsInN1YiI6InB5Z2xpZGVpbkBpY2VjdWJlLndpc2MuZWR1In0.Qra4o3BSQ_Mx0hZavOrP6vHDnXntX0N2WcLgrKKaV0M
export ResourceName=$SITE

# Using Apptainer from CVMFS because it is more up-to-date 
export SINGULARITY_BIN=$HOME/install-dir/bin/apptainer
# /opt/singularitypro41/bin/singularity
# /cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.4.1/x86_64/bin/apptainer

# Image below comes from docker://hub.opensciencegrid.org/opensciencegrid/osgvo-docker-pilot:3.6-release 
# Not auto pulling cause OSG tends to make changes that break or change beahvior in unexpcted way
export BASE_IMAGE=/cosmos/nfs/home/briedel/test_rocm_osg.sif
# /u/riedel1/osgvo-docker-pilot_23-cuda_11_8_0-release.sif
# /scratch/bbfw/riedel1/osgvo-docker-pilot_apptainer_nvidia_nvvm.sif
# /u/riedel1/osgvo-docker-pilot_gpu.sif
# /projects/bbfw/riedel1/osgvo-docker-pilot.sif

export APPTAINERENV_CVMFS_QUOTA_LIMIT=120000

echo "Invoke the cvmfsexec env"
${LOCAL_DIR}/cvmfsexec_mine/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh

#!/bin/bash
#SBATCH --job-name="glidein"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=56
#SBATCH --partition=normal
#SBATCH --time=24:00:00
#SBATCH --output=/scratch1/04799/tg840985/out/test_%j.out
#SBATCH --error=/scratch1/04799/tg840985/out/test_%j.err
#SBATCH --export=ALL
#SBATCH -A PHY20012

echo `date`

echo "-----------------------------------------------------"
printenv
echo "-----------------------------------------------------"

export LOCAL_TMP_DIR=/tmp/icecube

echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
ls /tmp
echo "-----------------------------------------------------"
ls ${LOCAL_TMP_DIR}
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"

rm -rf ${LOCAL_TMP_DIR} || { find ${LOCAL_TMP_DIR} -user $USER -exec rm -rf {} \ ; } || { echo 'rm tmp failed' ; exit 1; }

mkdir -p ${LOCAL_TMP_DIR}/cache
mkdir -p ${LOCAL_TMP_DIR}/glidein

cp -a ${SCRATCH}/cvmfs/cvmfsexec ${LOCAL_TMP_DIR}/cvmfsexec

${LOCAL_TMP_DIR}/cvmfsexec/umountrepo -a
${LOCAL_TMP_DIR}/cvmfsexec/mountrepo config-osg.opensciencegrid.org
${LOCAL_TMP_DIR}/cvmfsexec/mountrepo oasis.opensciencegrid.org
${LOCAL_TMP_DIR}/cvmfsexec/mountrepo icecube.opensciencegrid.org


module load tacc-singularity

MEMORY=192000
WALLTIME=86400
CPUS=56
DISK=147456000000
GPUS=0
SITE="Frontera"
CLEANUP=0
LOCAL_DIR=${SCRATCH}/glidein/${SLURM_JOB_ID}
if [ ! -d $LOCAL_DIR ]; then
    mkdir -p $LOCAL_DIR
    CLEANUP=1
fi
cd $LOCAL_DIR
echo $PWD
cp /home1/04799/tg840985/pyglidein/pyglidein/glidein_start.sh glidein_start.sh
cp /home1/04799/tg840985/pyglidein/pyglidein/os_arch.sh os_arch.sh
cp /home1/04799/tg840985/pyglidein/pyglidein/log_shipper.sh log_shipper.sh
cp /home1/04799/tg840985/pyglidein/pyglidein/startd_cron_scripts/clsim_gpu_test.py clsim_gpu_test.py
cp /home1/04799/tg840985/pyglidein/pyglidein/startd_cron_scripts/cvmfs_test.py cvmfs_test.py
cp /home1/04799/tg840985/pyglidein/pyglidein/startd_cron_scripts/gridftp_test.py gridftp_test.py
cp /home1/04799/tg840985/pyglidein/pyglidein/startd_cron_scripts/post_cvmfs.sh post_cvmfs.sh
cp /home1/04799/tg840985/pyglidein/pyglidein/startd_cron_scripts/pre_cvmfs.sh pre_cvmfs.sh
SINGULARITYENV_RETIRETIME=12000 SINGULARITYENV_DISK=$DISK SINGULARITYENV_CPUS=$CPUS SINGULARITYENV_GPUS=$GPUS SINGULARITYENV_MEMORY=$MEMORY SINGULARITYENV_WALLTIME=$WALLTIME SINGULARITYENV_DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS SINGULARITYENV_SITE=$SITE SINGULARITYENV_ResourceName=$SITE singularity exec --bind /tmp/icecube/cvmfsexec/dist/cvmfs:/cvmfs --cleanenv docker://htcondor/build-centos7:V8_9_7 ./glidein_start.sh 

${LOCAL_TMP_DIR}/cvmfsexec/umountrepo -a

if [ $CLEANUP -eq 1 ]; then
    rm -rf $LOCAL_DIR
fi
rm -rf ${LOCAL_TMP_DIR}

echo `date`


#!/bin/bash -ex

# Installing base packages
yum -y install \
cron \
epel-release \
glibc-static \
libgomp \
libstdc++-static \
perl \
openssl \
wget

# Updating ca certs to get epel mirrors to work
yum -y upgrade ca-certificates --disablerepo=epel

yum -y groupinstall 'Development Tools'

# Installing condor
useradd condor
su -c "wget http://prod-exe.icecube.wisc.edu/htcondor/condor-8.7.2-x86_64_RedHat7-stripped.tar.gz" - condor
su -c "mkdir ~/condor-8.7.2; cd ~/condor-8.7.2; mkdir local" - condor
su -c "cd ~/condor-8.7.2; tar -z -x -f ~/condor-8.7.2-*-stripped.tar.gz" - condor
su -c "cd ~/condor-8.7.2; ./condor-8.7.2-*-stripped/condor_install --local-dir /home/condor/condor-8.7.2/local --make-personal-condor" - condor
rm -f /home/condor/condor-8.7.2-x86_64_RedHat7-stripped.tar.gz
chmod 755 /home/condor
chmod 755 /home/condor/condor-8.7.2/condor.sh

# Installing pyglidein
useradd pyglidein
tar xvzf pyglidein.tar.gz
#TODO: Cleanup how condor handles job outputs
mkdir /pyglidein/out
chown -R pyglidein:pyglidein /pyglidein
#TODO: Cleanup how condor handles job outputs
chmod 777 /pyglidein
chmod 777 /pyglidein/out
yum -y install python-pip
pip install tornado

# Installing Runit
wget http://smarden.org/runit/runit-2.1.2.tar.gz
tar xvzf runit-2.1.2.tar.gz
cd admin/runit-2.1.2/
./package/install
cd /
rm -f runit-2.1.2.tar.gz

# Installing CVMFS
yum -y install \
gawk \
fuse \
fuse-libs \
autofs \
attr \
gdb \
policycoreutils-python

rpm -ivh https://ecsft.cern.ch/dist/cvmfs/cvmfs-config/cvmfs-config-default-1.4-1.noarch.rpm
rpm -ivh --nodeps https://ecsft.cern.ch/dist/cvmfs/cvmfs-2.3.5/cvmfs-2.3.5-1.el7.centos.x86_64.rpm

# Adding automounter configs
echo "user_allow_other" >> /etc/fuse.conf
echo "/cvmfs /etc/auto.cvmfs" >> /etc/auto.master

# Adding icecube CVMFS configs
cat <<EOF >> /etc/cvmfs/default.local
CVMFS_REPOSITORIES='icecube.opensciencegrid.org'
CVMFS_HTTP_PROXY='DIRECT'
EOF

# Creating service links
mkdir /etc/service
ln -s /etc/sv/condor /etc/service/condor
ln -s /etc/sv/pyglidein_client /etc/service/pyglidein_client
ln -s /etc/sv/autofs /etc/service/autofs

# Creating data directory
mkdir /data/
mkdir /data/log
mkdir /data/log/condor
mkdir /data/log/pyglidein_client
mkdir /data/log/autofs

# Removing packages
yum -y groupremove 'Development Tools'

# Removing root tarball
rm -f /root.tar.gz

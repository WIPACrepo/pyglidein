#!/bin/bash -ex

# Installing base packages
yum -y install \
epel-release \
glibc-static \
libgomp \
libstdc++-static \
perl \
wget

 yum -y groupinstall 'Development Tools'

# Installing condor
useradd condor
su -c "wget http://parrot.cs.wisc.edu//symlink/20170831031502/8/8.7/8.7.2/45206b44b09ded700710a88925fcc149/condor-8.7.2-x86_64_RedHat7-stripped.tar.gz" - condor
su -c "mkdir ~/condor-8.7.2; cd ~/condor-8.7.2; mkdir local" - condor
su -c "cd ~/condor-8.7.2; tar -z -x -f ~/condor-8.7.2-*-stripped.tar.gz" - condor
su -c "cd ~/condor-8.7.2; ./condor-8.7.2-*-stripped/condor_install --local-dir /home/condor/condor-8.7.2/local --make-personal-condor" - condor
rm -f /home/condor/condor-8.7.2-x86_64_RedHat7-stripped.tar.gz
chmod 755 /home/condor
chmod 755 /home/condor/condor-8.7.2/condor.sh

# Installing pyglidein
useradd pyglidein
tar xvzf pyglidein.tar.gz
yum -y install python-pip
pip install tornado

# Installing Runit
wget http://smarden.org/runit/runit-2.1.2.tar.gz
tar xvzf runit-2.1.2.tar.gz
cd admin/runit-2.1.2/
./package/install
cd /
rm -f runit-2.1.2.tar.gz

# Creating service links
mkdir /etc/service
ln -s /etc/sv/condor /etc/service/condor
ln -s /etc/sv/pyglidein_server /etc/service/pyglidein_server

# Creating data directory
mkdir /data/
mkdir /data/log
mkdir /data/log/condor
mkdir /data/log/pyglidein_server

# Removing packages
yum -y groupremove 'Development Tools'

# Removing root tarball
rm -f /root.tar.gz

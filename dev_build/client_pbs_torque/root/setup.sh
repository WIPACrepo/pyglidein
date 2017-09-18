#!/bin/bash -ex

# Installing base packages
yum -y install \
boost-devel \
epel-release \
glibc-static \
iproute \
libgomp \
libtool \
libstdc++-static \
libxml2-devel \
perl \
openssl \
openssl-devel \
wget

# Updating ca certs to get epel mirrors to work
yum -y upgrade ca-certificates --disablerepo=epel

yum -y groupinstall 'Development Tools'

# Installing PBS Torque
cd /usr/local
git clone https://github.com/adaptivecomputing/torque.git -b 6.1.1 6.1.1
cd 6.1.1
./autogen.sh
./configure --enable-cpusets --with-default-server=localhost
make -j 8
make install
. /etc/profile.d/torque.sh
yes | ./torque.setup root localhost

echo "\$pbsserver localhost" >> /var/spool/torque/mom_priv/config
echo "\$exec_with_exec true" >> /var/spool/torque/mom_priv/config
echo "localhost" >> /var/spool/torque/server_priv/nodes
echo "pyglidein-client-pbs-torque np=8" >> /var/spool/torque/server_priv/nodes

# Installing pyglidein
cd /
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
pip install minio

# Downloading pyglidein tarball
wget -O /pyglidein/glidein.tar.gz -nv http://prod-exe.icecube.wisc.edu/glidein-RHEL_7_x86_64.tar.gz

# Installing Runit
wget -nv http://smarden.org/runit/runit-2.1.2.tar.gz
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
ln -s /etc/sv/autofs /etc/service/autofs
ln -s /etc/sv/trqauthd /etc/service/trqauthd
ln -s /etc/sv/pbs_mom /etc/service/pbs_mom
ln -s /etc/sv/pbs_server /etc/service/pbs_server
ln -s /etc/sv/pbs_sched /etc/service/pbs_sched
ln -s /etc/sv/pyglidein_client /etc/service/pyglidein_client
#ln -s /etc/sv/autofs /etc/service/autofs

# Creating data directory
mkdir /data/
mkdir /data/log
mkdir /data/log/trqauthd
mkdir /data/log/pbs_mom
mkdir /data/log/pbs_sched
mkdir /data/log/pbs_server
mkdir /data/log/pyglidein_client
#mkdir /data/log/autofs

# Removing packages
#yum -y groupremove 'Development Tools'

# Removing root tarball
rm -f /root.tar.gz

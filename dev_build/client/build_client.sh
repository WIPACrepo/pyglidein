#!/bin/bash -e

OS_VERSION=$1

# Copy pyglidein egg to inside container
rm -f root/pyglidein-*
cp ../../dist/pyglidein* root/
rm -f root.tar.gz
cd root
tar czvf ../root.tar.gz .
cd ..
docker build --build-arg OS_VERSION=${OS_VERSION} -t wipac/pyglidein_client_centos${OS_VERSION}:1.0 .

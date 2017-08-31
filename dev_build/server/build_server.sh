#!/bin/bash -e
rm -f root/pyglidein.tar.gz
tar -C ../../../ --exclude=pyglidein/build --exclude=pyglidein/.git -czvf root/pyglidein.tar.gz pyglidein
rm -f root.tar.gz
cd root; tar czvf ../root.tar.gz .
cd ..
docker build -t wipac/pyglidein_server:1.0 .

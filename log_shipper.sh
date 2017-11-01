#!/bin/bash

PRESIGNED_PUT_URL=$1

# Waiting for condor to start
sleep 10

while true
do
  tar czf logs.tar.gz log.*
  unset http_proxy
  curl --silent --upload-file logs.tar.gz ${PRESIGNED_PUT_URL}
  rm -f logs.tar.gz
  sleep 300
done

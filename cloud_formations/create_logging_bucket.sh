#!/bin/bash

BUCKET_NAME=$1
EMAIL=$2
echo BUCKET_NAME=$BUCKET_NAME
echo EMAIL=$EMAIL

# aws ec2 create-key-pair --key-name cloudy_cluster
aws cloudformation create-stack --stack-name ${BUCKET_NAME}-bucket --template-body file://logging_bucket.json \
  --parameters ParameterKey=BucketName,ParameterValue=${BUCKET_NAME} \
  ParameterKey=Email,ParameterValue=${EMAIL} \
  --capabilities CAPABILITY_IAM

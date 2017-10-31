#!/bin/bash

BUCKET_NAME=$1

# aws ec2 create-key-pair --key-name cloudy_cluster
aws cloudformation create-stack --stack-name ${BUCKET_NAME}-bucket --template-body file://logging_bucket.json \
  --parameters ParameterKey=BucketName,ParameterValue=${BUCKET_NAME} \
  --capabilities CAPABILITY_IAM

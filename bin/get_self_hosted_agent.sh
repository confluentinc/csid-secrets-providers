#!/bin/bash

#retrieve ec2 instance metadata for semaphore jobs
INSTANCE_TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
INSTANCE_ID=`curl -H "X-aws-ec2-metadata-token: $INSTANCE_TOKEN" --fail --silent --show-error --location "http://169.254.169.254/latest/meta-data/instance-id"`
echo "Job is running on Semaphore self-hosted agents. AWS ec2 instance id: $INSTANCE_ID"

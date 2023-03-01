#!/bin/bash

version=$6
launch=$5
image=$4
storage=$3
acc=$2
region=$1
echo $region
echo $acc
export AWS_PROFILE=$acc
echo "creating"
INSTANCE_ID=$(aws ec2 run-instances --image-id $image --instance-type t2.micro --region $region --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeType":"gp3","DeleteOnTermination":true,"VolumeSize":'$storage'}}]' --query 'Instances[0].InstanceId' --output text)
echo "Created instance with ID: $INSTANCE_ID"
echo "wait for 90 seconds"
sleep 90
ami=$(aws ec2 create-image --instance-id $INSTANCE_ID --name "ami-i-$INSTANCE_ID" --region $region --description "ami-of-instance-$INSTANCE_ID" --output text)
echo "image creation sleeping for 210 secs"
sleep 210
aws ec2 terminate-instances --region $region --instance-ids $INSTANCE_ID
./update-launch-template.sh "$region" "$acc" "$launch" "$ami" "$version"

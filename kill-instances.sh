#!/usr/bin/env bash

acc=$2
region=$1
export AWS_PROFILE=$acc

LIST=$(cat instances.txt)

for instance in $LIST; do
    echo "killing $instance"
    aws ec2 terminate-instances --region $region --instance-ids $instance --query="TerminatingInstances[0].[InstanceId,CurrentState.Name]" 
done



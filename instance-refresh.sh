#!/usr/bin/env bash

acc=$2
region=$1
export AWS_PROFILE=$acc

LIST=$(aws autoscaling describe-auto-scaling-groups --region="$region" --query="AutoScalingGroups[*].AutoScalingGroupName" --output=text)

for group in $LIST; do
    echo "$group"
    aws autoscaling start-instance-refresh \
        --auto-scaling-group-name my-asg \
        --preferences '{"MinHealthyPercentage": 50,"SkipMatching": true,"ScaleInProtectedInstances": "Refresh"}' --region $region
done

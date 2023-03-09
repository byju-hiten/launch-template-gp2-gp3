#!/usr/bin/env bash

acc=$2
region=$1
export AWS_PROFILE=$acc

LIST=$(aws autoscaling describe-auto-scaling-groups --region $region --query="AutoScalingGroups[*].AutoScalingGroupName" --output text)

for groupName in $LIST; do
    echo $groupName
    configName=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $groupName --region $region --query="AutoScalingGroups[*].LaunchConfigurationName" --output text)
    if [ -n "$configName" ]; then
        echo "convert to launch template"
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name $groupName \
            --launch-template LaunchTemplateName="$configName",Version='$Default' --region $region
    fi
done

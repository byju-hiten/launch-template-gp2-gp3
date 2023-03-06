#!/usr/bin/env bash

acc=$2
region=$1
echo $region
echo $acc
export AWS_PROFILE=$acc

while read -r groupName launch versionInfo version gp2image; do
    echo "Rolling back $groupName with launch template id - $launch"
    if [ $versionInfo == "\$Latest" ]; then
        newVersion=$(aws ec2 describe-launch-template-versions --launch-template-id "$launch" --versions "$versionInfo" --query="LaunchTemplateVersions[0].VersionNumber" --region="$region" --output text)
        aws ec2 delete-launch-template-versions --launch-template-id "$launch" --versions "$newVersion" --region $region
        aws autoscaling start-instance-refresh \
            --auto-scaling-group-name $groupName \
            --preferences '{"MinHealthyPercentage": 50,"SkipMatching": true,"ScaleInProtectedInstances": "Refresh","InstanceWarmup": 120}' --region $region
    fi
    if [ $versionInfo == "\$Default" ]; then
        aws ec2 modify-launch-template --launch-template-id "$launch" --default-version "$version" --region $region
        aws autoscaling start-instance-refresh \
            --auto-scaling-group-name $groupName \
            --preferences '{"MinHealthyPercentage": 50,"SkipMatching": true,"ScaleInProtectedInstances": "Refresh","InstanceWarmup": 120}' --region $region
    fi
done >logs.txt

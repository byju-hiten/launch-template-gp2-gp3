#!/bin/bash

version=$5
ami=$4
launch=$3
acc=$2
region=$1
echo $region
echo $acc
export AWS_PROFILE=$acc

VERSION_NO=$(aws ec2 create-launch-template-version --launch-template-id "$launch" --query="LaunchTemplateVersion.VersionNumber" --version-description gp3Image --source-version $version --launch-template-data '{"ImageId":"'$ami'"}' --region $region --output text)
aws ec2 modify-launch-template --launch-template-id "$launch" --default-version "$VERSION_NO" --region $region

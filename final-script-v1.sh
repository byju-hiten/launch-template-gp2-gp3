#!/bin/bash

acc=$2
region=$1
echo $region
echo $acc
export AWS_PROFILE=$acc

LIST=$(aws ec2 describe-launch-templates --region $region --query="LaunchTemplates[*].LaunchTemplateId" --output text)

for launch in $LIST; do
   echo "$launch"
   image=$(aws ec2 describe-launch-template-versions --launch-template-id "$launch" --filters "Name=is-default-version,Values=true" --query="LaunchTemplateVersions[0].LaunchTemplateData.ImageId" --region="$region" --output text)
   version=$(aws ec2 describe-launch-template-versions --launch-template-id "$launch" --filters "Name=is-default-version,Values=true" --query="LaunchTemplateVersions[0].VersionNumber" --region="$region" --output text)
   if [ $image != "None" ]; then
      gp2image=$(aws ec2 describe-images --filters "Name=block-device-mapping.volume-type,Values=gp2" --image-ids "$image" --region="$region" --query="Images[0].ImageId" --output text)
      if [ $gp2image != "None" ]; then
         storage=$(aws ec2 describe-images --filters "Name=block-device-mapping.volume-type,Values=gp2" --image-ids "$gp2image" --region="$region" --query="Images[0].BlockDeviceMappings[0].Ebs.VolumeSize" --output text)
         ./create-ami.sh "$region" "$acc" "$storage" "$gp2image" "$launch" "$version"
      fi
   fi
done

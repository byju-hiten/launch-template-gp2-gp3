#!/bin/bash

declare -A newmap

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
            #  ./create-ami.sh "$region" "$acc" "$storage" "$gp2image" "$launch" "$version"
            if [ -z ${newmap[gp2image]} ]; then
                echo "creating"
                INSTANCE_ID=$(aws ec2 run-instances --image-id $gp2image --instance-type t2.micro --region $region --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeType":"gp3","DeleteOnTermination":true,"VolumeSize":'$storage'}}]' --query 'Instances[0].InstanceId' --output text)
                echo "Created instance with ID: $INSTANCE_ID"
                echo "wait for 90 seconds"
                sleep 90
                ami=$(aws ec2 create-image --instance-id $INSTANCE_ID --name "ami-i-$INSTANCE_ID" --region $region --description "ami-of-instance-$INSTANCE_ID" --output text)
                echo "image creation sleeping for 210 secs"
                sleep 210
                aws ec2 terminate-instances --region $region --instance-ids $INSTANCE_ID
                newmap[gp2image]="$ami"
                ./update-launch-template.sh "$region" "$acc" "$launch" "$ami" "$version"
            else
                ./update-launch-template.sh "$region" "$acc" "$launch" "${newmap[gp2image]}" "$version"
            fi
        fi
    fi
done

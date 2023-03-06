#!/usr/bin/env bash

declare -A newmap

acc=$2
region=$1
echo $region
echo $acc
export AWS_PROFILE=$acc

rm -f ./instances.txt

LIST=$(aws autoscaling describe-auto-scaling-groups --region $region --query="AutoScalingGroups[*].AutoScalingGroupName" --output text)

for groupName in $LIST; do

    launch=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$groupName" --region $region --query="AutoScalingGroups[*].MixedInstancesPolicy.LaunchTemplate.LaunchTemplateSpecification.LaunchTemplateId" --output text)
    versionInfo=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$groupName" --region $region --query="AutoScalingGroups[*].MixedInstancesPolicy.LaunchTemplate.LaunchTemplateSpecification.Version" --output text)
    if [ -z $launch ]; then
        launch=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$groupName" --region $region --query="AutoScalingGroups[*].LaunchTemplate.LaunchTemplateId" --output text)
        versionInfo=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$groupName" --region $region --query="AutoScalingGroups[*].LaunchTemplate.Version" --output text)
    fi
    if [ -z $launch ]; then
        continue
    fi
    echo $groupName
    echo $launch
    echo $versionInfo
    image=$(aws ec2 describe-launch-template-versions --launch-template-id "$launch" --filters "Name=is-default-version,Values=true" --query="LaunchTemplateVersions[0].LaunchTemplateData.ImageId" --region="$region" --output text)
    if [ $image != "None" ]; then
        gp2image=$(aws ec2 describe-images --filters "Name=block-device-mapping.volume-type,Values=gp2" --image-ids "$image" --region="$region" --query="Images[0].ImageId" --output text)
        version=$(aws ec2 describe-launch-template-versions --launch-template-id "$launch" --versions "$versionInfo" --query="LaunchTemplateVersions[0].VersionNumber" --region="$region" --output text)
        if [ $gp2image != "None" ]; then
            echo "has gp2 image $gp2image"
            storage=$(aws ec2 describe-images --filters "Name=block-device-mapping.volume-type,Values=gp2" --image-ids "$gp2image" --region="$region" --query="Images[0].BlockDeviceMappings[0].Ebs.VolumeSize" --output text)
            if [ -z ${newmap["$gp2image"]} ]; then
                echo "creating as no similar gp2 image exists"
                INSTANCE_ID=$(aws ec2 run-instances --image-id $gp2image --instance-type t2.micro --region $region --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeType":"gp3","DeleteOnTermination":true,"VolumeSize":'$storage'}}]' --query 'Instances[0].InstanceId' --output text)
                echo "Created instance with ID: $INSTANCE_ID"
                echo "$INSTANCE_ID" >>instances.txt
                echo "wait for 90 seconds"
                sleep 90
                ami=$(aws ec2 create-image --instance-id $INSTANCE_ID --name "ami-i-$INSTANCE_ID" --region $region --description "ami-of-instance-$INSTANCE_ID" --output text)
                echo "new gp3 image $ami created"
                newmap["$gp2image"]="$ami"
                echo "$ami" >>new-ami.txt
                ./update-launch-template.sh "$region" "$acc" "$launch" "$ami" "$version"
            else
                echo "similar gp3 image exists , using that"
                ./update-launch-template.sh "$region" "$acc" "$launch" "${newmap["$gp2image"]}" "$version"
            fi
            echo "starting instance refresh fpr $groupName"
            echo "$groupName" "$launch" "$versionInfo" "$version" "$gp2image" >>logs.txt
            aws autoscaling start-instance-refresh \
                --auto-scaling-group-name $groupName \
                --preferences '{"MinHealthyPercentage": 50,"SkipMatching": true,"ScaleInProtectedInstances": "Refresh","InstanceWarmup": 120}' --region $region
        fi
    fi
done

echo "sleeping for 210 seconds for image creation"
sleep 210
./kill-instances.sh "$region" "$acc"
wait

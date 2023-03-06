#!/usr/bin/env bash

acc=$2
region=$1
echo $region
echo $acc
export AWS_PROFILE=$acc
# Find all volumes that are currently using the gp2 volume type
gp2_volumes=$(aws ec2 describe-volumes --region $region --filters Name=volume-type,Values=gp2 --query 'Volumes[*].{ID:VolumeId}' --output text)
# Loop through each volume and convert it to the gp3 volume type
for volume in $gp2_volumes; do
    echo "===== converting $volume"
    aws ec2 modify-volume --volume-id $volume --volume-type gp3 --region $region
    echo $volume
done
echo "Conversion complete!"

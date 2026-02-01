#!/bin/bash

SG_ID="sg-0e3e5d0160ba94b0b"
AMI_ID="ami-0220d79f3f480ecf5"
ROUTE53_ZONE_ID="Z032594897Q2I0KZ7GR1"
DOMAIN_NAME="rkak87.online"

for instance in $@
do
    echo -n "Creating EC2 instance for ${instance} ... "
    INSTANCE_ID=$( aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text )

        if [ $instance == "frontend" ]; then
            aws ec2 wait instance-running --instance-ids $INSTANCE_ID
            IP_ADDRESS=$(
                aws ec2 describe-instances \
                --instance-ids $INSTANCE_ID \
                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                --output text 
                )
            echo "Instance created with Instance ID: $INSTANCE_ID and Public IP: $IP_ADDRESS"
            RECORD_NAME="webapp.$DOMAIN_NAME"
        else
            aws ec2 wait instance-running --instance-ids $INSTANCE_ID
            IP_ADDRESS=$(
                aws ec2 describe-instances \
                --instance-ids $INSTANCE_ID \
                --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                --output text 
                )
            echo "Instance created with Instance ID: $INSTANCE_ID and Private IP: $IP_ADDRESS"
            RECORD_NAME="$instance.$DOMAIN_NAME"
        fi
# Update Route 53 DNS Record
        DNS_RECORD=$(aws route53 change-resource-record-sets \
        --hosted-zone-id $ROUTE53_ZONE_ID \
        --change-batch '
        {
            "Comment": "Updating record",
            "Changes": [
                {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$RECORD_NAME'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [
                    {
                        "Value": "'$IP_ADDRESS'"
                    }
                    ]
                }
                }
            ]
        }
        '
        )
    echo "DNS Record $DNS_RECORD updated for $instance"
done
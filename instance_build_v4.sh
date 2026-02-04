#!/bin/bash

SG_ID="sg-0e3e5d0160ba94b0b"
AMI_ID="ami-0220d79f3f480ecf5"
DOMAIN_NAME="rkak87.online"
ROUTE53_ZONE_ID="Z032594897Q2I0KZ7GR1"

#Color Codes
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

#check the user account has root privileges
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
  echo -e "$RED You should run this script as root user or with sudo privileges$RESET"
  exit 1
fi

#Instance build with Route53 record creation
for each_instance in $@
do
    echo -e "$YELLOW Creating EC2 Instance and Route53 record...$RESET"
    INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$each_instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )
    echo -e "$GREEN Instance Created with Instance ID: $INSTANCE_ID $RESET"
    #wait till instance up and running
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID
    echo -e "$GREEN $each_instance Instance ($INSTANCE_ID) is running now $RESET"
    if  [ $each_instance == "frontend" ]; then
        IP_ADDRESS=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
            )
        echo -e "$GREEN Instance created with Instance ID: $INSTANCE_ID and Public IP: $IP_ADDRESS $RESET"
        RECORD_NAME="webapp.$DOMAIN_NAME"
    else
        IP_ADDRESS=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
            )
        echo -e "$GREEN Instance created with Instance ID: $INSTANCE_ID and Private IP: $IP_ADDRESS $RESET"
        RECORD_NAME="$each_instance.$DOMAIN_NAME"
    fi
    #Update Route 53 DNS Record
    DNS_RECORD=$(
        aws route53 change-resource-record-sets \
        --hosted-zone-id $ROUTE53_ZONE_ID \
        --change-batch '
        {
            "Comment": "Updating DNS record for '$each_instance'",
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
    echo -e "$GREEN DNS record created/updated for $RECORD_NAME with IP $IP_ADDRESS $RESET"
done
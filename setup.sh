#!/bin/bash

region=us-west-2
stack_name=aws-ec2-vpn
vpn_pre_shared_key=$1
vpn_username=$2
vpn_password=$3

if [[ -z "${vpn_pre_shared_key// }" ]] ||
   [[ -z "${vpn_username// }" ]] ||
   [[ -z "${vpn_username// }" ]]; then
   echo "Usage: $0 VPN_PRE_SHARED_KEY VPN_USERNAME VPN_PASSWORD"
   exit 1
fi

which aws > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "aws cli must be installed and in path."
    exit 1
fi

which jq > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "jq must be installed and in path."
    exit 1
fi

set -e

az=`aws ec2 describe-availability-zones --region $region |jq -r .AvailabilityZones[0].ZoneName`

result=`aws cloudformation create-stack \
    --region $region \
    --stack-name $stack_name \
    --template-body file://aws-ec2-vpn.json \
    --capabilities CAPABILITY_IAM \
    --parameters \
    ParameterKey=AvailabilityZone,ParameterValue=$az \
    ParameterKey=VpnPreSharedKey,ParameterValue=$vpn_pre_shared_key \
    ParameterKey=VpnUserName,ParameterValue=$vpn_username \
    ParameterKey=VpnPassword,ParameterValue=$vpn_password`

echo "VPN Setup in progress."

aws cloudformation wait stack-create-complete \
    --region $region \
    --stack-name $stack_name

ip=`aws cloudformation describe-stacks \
    --region $region \
    --stack-name $stack_name |jq -r .Stacks[0].Outputs[0].OutputValue`

echo "VPN Setup complete. IP address is '$ip'."

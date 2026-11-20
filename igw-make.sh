#!/bin/bash

NAME=unset
VPC_ID=unset

usage() {
  echo "Usage: $0 -n <name> -v <vpc-id>" >&2
  exit 1
}

PARSED_ARGUMENTS=$(getopt -a -n script -o n:v: --long name:,vpc_id: -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  usage
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do 
  case "$1" in
   -n | --name) NAME="$2" ; shift 2 ;;
   -v | --vpc-id) VPC_ID="$2" ; shift 2 ;;
   --) shift; break ;;
   *) echo "Unexpected option: $1" >&2; usage ;;
  esac
done

if [ "$NAME" = "unset" ] || [ "$VPC_ID" = "unset" ] ; then
  echo "Error: all params are required" >&2
  usage
fi

create_igw=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${NAME}}]" --output text)

touch igw_data

echo "Created Internet Gateway"

cat <<< "$create_igw" > igw_data

igw_id=$(grep -oE '[^[:space:]]*igw[^[:space:]]*' igw_data)

echo "About to attach IGW $igw_id to VPC..."

aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $VPC_ID
echo "IGW successfully attached to vpc: $VPC_ID"

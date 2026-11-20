#!/bin/bash

VPC_ID=unset
CIDR_ID=unset
AZ_ID=unset
NAME=unset

usage() {
  echo "Usage: $0 -a <az> -n <name> -v <vpc-id> -c <cidr>" >&2
  exit 1
}


PARSED_ARGUMENTS=$(getopt -a -n script -o a:n:v:c: --long availability-zone:,name:,vpc-id:cidr: -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  usage
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do 
  case "$1" in
   -a | --availability-zone) AZ_ID="$2" ; shift 2 ;;
   -n | --name) NAME="$2" ; shift 2 ;;
   -v | --vpc-id) VPC_ID="$2" ; shift 2 ;;
   -c | --cidr) CIDR_ID="$2" ; shift 2 ;;
   --) shift; break ;;
   *) echo "Unexpected option: $1" >&2; usage ;;
  esac
done

if [ "$NAME" = "unset" ] || [ "$CIDR_ID" = "unset" ] || [ "$AZ_ID" = "unset" ] || [ "$VPC_ID" = "unset" ] ; then
  echo "Error: all params are required" >&2
  usage
fi

create_public_subnet=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $CIDR_ID --availability-zone $AZ_ID --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${NAME}}]" --output text)

echo "Creating public subnet..."

touch public_subnet_data

cat <<< "$create_public_subnet" > public_subnet_data

public_subnet_id=$(awk '{print $14}' public_subnet_data)

echo "Created public subnet of id $public_subnet_id"

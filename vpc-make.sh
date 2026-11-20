#!/bin/bash

NAME=unset
CIDR=unset

usage() {
  echo "Usage: $0 -n <name> -c <cidr>" >&2
  exit 1
}

PARSED_ARGUMENTS=$(getopt -a -n script -o n:c: --long name:,cidr: -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  usage
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do 
  case "$1" in
   -n | --name) NAME="$2" ; shift 2 ;;
   -c | --cidr) CIDR="$2" ; shift 2 ;;
   --) shift; break ;;
   *) echo "Unexpected option: $1" >&2; usage ;;
  esac
done

if [ "$NAME" = "unset" ] || [ "$CIDR" = "unset" ]; then
  echo "Error: Both --name and ---cidr are required." >&2
  usage
fi

echo "NAME: $NAME -- CIDR: $CIDR"

create_vpc=$(aws ec2 create-vpc --cidr-block "$CIDR" --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${NAME}}]" --output text)

touch vpc_data

cat <<< "$create_vpc" > vpc_data

vpc_id=$(awk '{print $8}' vpc_data)

echo "VPC CREATED!
VPC-ID:$vpc_id"

aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames

rm vpc_data

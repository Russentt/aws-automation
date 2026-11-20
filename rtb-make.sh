#!/bin/bash

NAME=unset
VPC_ID=unset

usage() {
  echo "Usage: $0 -n <name> -v <vpc-id>" >&2
  exit 1
}

PARSED_ARGUMENTS=$(getopt -a -n script -o n:v: --long name:,vpc-id: -- "$@")
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

create_rtb=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${NAME}}]" --output text)

touch rtb_data

cat <<< "$create_rtb" > rtb_data

rtb_id=$(grep -oE '[^[:space:]]*rtb[^[:space:]]*' rtb_data)

echo "Created route table $rtb_id"

read -rp "Internet Gateway ID: " igw_id

echo "Adding a route to IGW"

create_route=$(aws ec2 create-route --route-table-id $rtb_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id)

# Associate Public Subnet.

echo "Associating the public subnet"

read -rp "Public subnet id: " public_subnet_id

associate_rtb=$(aws ec2 associate-route-table --route-table-id $rtb_id --subnet-id $public_subnet_id)

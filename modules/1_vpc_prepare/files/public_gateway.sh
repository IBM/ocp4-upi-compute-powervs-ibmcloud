#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# This script adds public gateways to subnets which don't yet have public gateways.

API_KEY="${1}"
REGION="${2}"
RESOURCE_GROUP="${3}"
NAME_PREFIX="${4}"

if [ -z "$(command -v ibmcloud)" ]
then
  echo "ibmcloud CLI doesn't exist, installing"
  curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
else
  ibmcloud update -f
fi

ibmcloud login --apikey "${API_KEY}" -r "${REGION}" -g "${RESOURCE_GROUP}"
ibmcloud plugin install -f cloud-internet-services vpc-infrastructure cloud-object-storage is

# Pin the version to 0.4.9 (v1.0.0 may be incompatible)
ibmcloud plugin install -v 0.4.9 -f power-iaas

ibmcloud is vpc rdr-mac-qe-varad-tor-vpc --show-attached --output json | jq -r '.subnets[]' > subnets.json
cat subnets.json | jq -cr '.name,.public_gateway'

VPC_NAME=rdr-mac-qe-varad-tor-vpc
for SUBNET in $(cat subnets.json | jq -cr '.name')
do
JSON=$(ibmcloud is subnet ${SUBNET} --vpc ${VPC_NAME} --output json)
PG=$(echo ${JSON} | jq -rc .public_gateway.name)
if [ "${PG}" = "null" ]
then
  echo "WARNING: Public Gateway doesn't exist for the subnet: ${SUBNET}"
  # Dev Note: 
  # Does it match one of the zones and counts are greater than zero
  if true # 
  then
    ZONE=$(echo ${JSON} | jq -rc .zone.name)
    # Check the Zone is one we're going to use
    # if match then create a public gateway
    ibmcloud is public-gateway-create gw-z1 ${VPC_NAME} ${ZONE} --resource-group-name ${RESOURCE_GROUP}
    ibmcloud is subnet-public-gateway-attach
  fi
fi
done


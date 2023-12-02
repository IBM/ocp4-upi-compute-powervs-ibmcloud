#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# This script adds public gateways to subnets which don't yet have public gateways.

API_KEY="${1}"
REGION="${2}"
RESOURCE_GROUP="${3}"
VPC_NAME="${4}"
ADD_GATEWAY="${5}"
Z1_COUNT="${6}"
Z1_ZONE="${7}"
Z1_HAS_PG=""
Z2_COUNT="${8}"
Z2_ZONE="${9}"
Z2_HAS_PG=""
Z3_COUNT="${10}"
Z3_ZONE="${11}"
Z3_HAS_PG=""

if [ -z "$(command -v ibmcloud)" ]
then
  echo "ibmcloud CLI doesn't exist, installing"
  curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
else
  ibmcloud update -f
fi

ibmcloud login --apikey "${API_KEY}" -r "${REGION}" -g "${RESOURCE_GROUP}"
ibmcloud plugin install -f vpc-infrastructure is

echo "Grabbing the Subnet Details"
ibmcloud is vpc ${VPC_NAME} --show-attached --output json | jq -r '.subnets[]' > subnets.json
cat subnets.json | jq -cr '.name,.public_gateway'

# Dev Note: only one PG can be added to a zone
for SUBNET in $(cat subnets.json | jq -cr '.name')
do
  JSON=$(ibmcloud is subnet ${SUBNET} --vpc ${VPC_NAME} --output json)
  PG=$(echo ${JSON} | jq -rc .public_gateway.name)
  if [ "${PG}" = "null" ]
  then
    echo "PG doesn't exist in : $PG"
  else
    if [ "${ADD_GATEWAY}" = "true" ] 
    then
      VPC_ZONE=$(echo ${JSON} | jq -rc .zone.name)
      if [ "${Z1_COUNT}" != "0" ] && [ "ZONE_${VPC_ZONE}" = "ZONE_${Z1_ZONE}" ]
      then
        echo "PG exists on zone"
        Z1_HAS_PG="true"
      elif [ "${Z2_COUNT}" != "0" ] && [ "ZONE_${VPC_ZONE}" = "ZONE_${Z2_ZONE}" ]
      then
        echo "PG exists on zone"
        Z2_HAS_PG="true"
      elif [ "${Z3_COUNT}" != "0" ] && [ "ZONE_${VPC_ZONE}" = "ZONE_${Z3_ZONE}" ]
      then
        echo "PG exists on zone"
        Z3_HAS_PG="true"
      else 
        echo "ZONE: ${VPC_ZONE} not configured for day-2 workers"
      fi
    fi
  fi
done

for SUBNET in $(cat subnets.json | jq -cr '.name')
do
  JSON=$(ibmcloud is subnet ${SUBNET} --vpc ${VPC_NAME} --output json)
  PG=$(echo ${JSON} | jq -rc .public_gateway.name)
  if [ "${PG}" = "null" ]
  then
    echo "WARNING: Public Gateway doesn't exist for the subnet: ${SUBNET}"
    echo "set vpc_create_public_gateways=true to create the public gateway"
    # Dev Note: 
    # Does it match one of the zones and counts are greater than zero
    if [ "${ADD_GATEWAY}" = "true" ] 
    then
      VPC_ZONE=$(echo ${JSON} | jq -rc .zone.name)
      if [ -z "${Z1_HAS_PG}" ] && [ "${Z1_COUNT}" != "0" ] && [ "ZONE_${VPC_ZONE}" = "ZONE_${Z1_ZONE}" ]
      then
        echo "Adding a public gateway to the zone - ${VPC_ZONE}"
        PGC_JSON=$(ibmcloud is public-gateway-create ${REGION}-z1-gw ${VPC_NAME} ${Z1_ZONE} --resource-group-name ${RESOURCE_GROUP} --output json)
        # Dev Note: for debug - echo "Public Gateway JSON is: " $( echo $PGC_JSON | jq -rc . )
        ibmcloud is subnet-update ${SUBNET} --pgw $(echo ${PGC_JSON} | jq -r '.id')
        Z1_HAS_PG="true"
      elif [ -z "${Z2_HAS_PG}" ] && [ "${Z2_COUNT}" != "0" ] && [ "ZONE_${VPC_ZONE}" = "ZONE_${Z2_ZONE}" ]
      then
        echo "Adding a public gateway to the zone - ${VPC_ZONE}"
        PGC_JSON=$(ibmcloud is public-gateway-create ${REGION}-z2-gw ${VPC_NAME} ${Z2_ZONE} --resource-group-name ${RESOURCE_GROUP} --output json)
        # Dev Note: for debug - echo "Public Gateway JSON is: " $( echo $PGC_JSON | jq -rc . )
        ibmcloud is subnet-update ${SUBNET} --pgw $(echo ${PGC_JSON} | jq -r '.id')
        Z2_HAS_PG="true"
      elif [ -z "${Z3_HAS_PG}" ] && [ "${Z3_COUNT}" != "0" ] && [ "ZONE_${VPC_ZONE}" = "ZONE_${Z3_ZONE}" ]
      then
        echo "Adding a public gateway to the zone - ${VPC_ZONE}"
        PGC_JSON=$(ibmcloud is public-gateway-create ${REGION}-z3-gw ${VPC_NAME} ${Z3_ZONE} --resource-group-name ${RESOURCE_GROUP} --output json)
        # Dev Note: for debug - echo "Public Gateway JSON is: " $( echo $PGC_JSON | jq -rc . )
        ibmcloud is subnet-update ${SUBNET} --pgw $(echo ${PGC_JSON} | jq -r '.id')
        Z3_HAS_PG="true"
      else 
        echo "ZONE: ${VPC_ZONE} not configured for day-2 workers"
      fi
    fi
  fi
done

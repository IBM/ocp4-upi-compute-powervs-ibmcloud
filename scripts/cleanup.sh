#!/usr/bin/env bash

################################################################
# Copyright 2024 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Facilitates the cleanup
# usage: vpc_name pvs_service_instance_id api_key region resource_group
#
# Process:
# 1. Transit Gateways
# 2. Delete artifacts in PowerVS
# 3. Delete VPC Artifacts
# 4. Delete VPC 
# 5. Delete PowerVS workspace

# Cleans up the failed prior jobs
function cleanup_mac() {
  local vpc_name="${1}"
  local pvs_service_instance_id="${2}"
  local api_key="${3}"
  local region="${4}"
  local resource_group="${5}"

  echo "Cleaning up the Transit Gateways"
  for GW in $(ibmcloud tg gateways --output json | jq -r '.[].id')
  do
    echo "Checking the resource_group and location for the transit gateways ${GW}"
    VALID_GW=$(ibmcloud tg gw "${GW}" --output json | jq -r '. | select(.name | contains("'${vpc_name}'"))')
    if [ -n "${VALID_GW}" ]
    then
      TG_CRN=$(echo "${VALID_GW}" | jq -r '.crn')
      TAGS=$(ibmcloud resource search "crn:\"${TG_CRN}\"" --output json | jq -r '.items[].tags[]' | grep "mac-cicd-${version}")
      if [ -n "${TAGS}" ]
      then
        for CS in $(ibmcloud tg connections "${GW}" --output json | jq -r '.[].id')
        do 
          ibmcloud tg connection-delete "${GW}" "${CS}" --force
          sleep 30
        done
        ibmcloud tg gwd "${GW}" --force
        echo "waiting up a minute while the Transit Gateways are removed"
        sleep 60
      fi
    fi
  done

  echo "Cleaning up workspaces for ${pvs_service_instance_id}"
  for CRN in $(ibmcloud pi workspace ls 2> /dev/null | grep "${pvs_service_instance_id}" | awk '{print $1}')
  do
    echo "Targetting power cloud instance"
    ibmcloud pi workspace target "${CRN}"

    echo "Deleting the PVM Instances"
    for INSTANCE_ID in $(ibmcloud pi instance ls --json | jq -r '.pvmInstances[] | .id')
    do
      echo "Deleting PVM Instance ${INSTANCE_ID}"
      ibmcloud pi instance delete "${INSTANCE_ID}" --delete-data-volumes
    done
    sleep 60

    echo "Deleting the Images"
    for IMAGE_ID in $(ibmcloud pi images ls --json | jq -r '.images[].imageID')
    do
      echo "Deleting Images ${IMAGE_ID}"
      ibmcloud pi image delete "${IMAGE_ID}"
      sleep 60
    done

    echo "Deleting the Network"
    for NETWORK_ID in $(ibmcloud pi network ls 2>&1| awk '{print $1}')
    do
      echo "Deleting network ${NETWORK_ID}"
      ibmcloud pi network delete "${NETWORK_ID}"
      sleep 60
    done

    # ibmcloud resource service-instance-update "${CRN}" --allow-cleanup true
    # sleep 30
    # ibmcloud resource service-instance-delete "${CRN}" --force --recursive
    echo "Done Deleting the ${CRN}"
  done

  echo "Deleting the PowerVS service instance"
  ibmcloud resource service-instance-delete "${pvs_service_instance_id}" -g "${resource_group}" --force --recursive \
    || (sleep 60 && ibmcloud resource service-instance-delete "${pvs_service_instance_id}" -g "${resource_group}" --force --recursive)

  echo "Delete the VPC Instance"
  ibmcloud is vpc-delete "${vpc_name}" --force --output json

  echo "Done cleaning up"
}

echo "usage: vpc_name pvs_service_instance_id api_key region resource_group"
cleanup_mac "${1}" "${2}" "${3}" "${4}" "${5}"
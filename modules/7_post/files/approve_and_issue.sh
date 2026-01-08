#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Approve and Issue CSRs for our generated amd64 workers only
# The hostname is of the style - ${name_prefix}-worker-${ZONE}-${index}

# Var: ${self.triggers.counts}
INTEL_COUNT="${1}"

# Var: ${self.triggers.approve}
INTEL_PREFIX="${2}"

INTEL_ZONE="${3}"

RESOURCE_GROUP_NAME="${4}"

# Machine Prefix
MACHINE_PREFIX="${INTEL_PREFIX}-worker-${INTEL_ZONE}"

if [ "0" -eq "${INTEL_COUNT}" ]
then
  echo "There are no workers in the ${INTEL_ZONE}"
  exit 0
fi

# List VPC compute instances in the resource group
list_vpc_instances() {
  echo "::::: Listing VPC compute instances"
  ibmcloud is instances --resource-group-name "${RESOURCE_GROUP_NAME}"
  echo "::::: End Listing VPC compute instances"
  return 0
}

echo "::::: START DEBUG :::::"
echo "::::: MCP :::::"
oc get mcp worker -oyaml
echo "::::: MC :::::"
oc get mc
echo "::::: NODES :::::"
oc get nodes
echo "::::: DONE DEBUG :::::"

IDX=0
READY_COUNT=$(oc get nodes -l kubernetes.io/arch=amd64 | grep "${MACHINE_PREFIX}" | grep -v NotReady | grep -c Ready)
while [ "${READY_COUNT}" -ne "${INTEL_COUNT}" ]
do
  echo "::::: Approve and Issue - #${IDX}"
  echo "List of Intel Workers in ${INTEL_ZONE}: "
  oc get nodes -l 'kubernetes.io/arch=amd64' --no-headers=true | grep "${MACHINE_PREFIX}"
  echo "::::: End List of Nodes"
  
  # List VPC instances to compare with OpenShift nodes
  echo "::::: Start VPC Instances"
  list_vpc_instances
  echo "::::: End VPC Instances"

  # Approve
  APPROVED_WORKERS=0
  JSON_BODY=$(oc get csr -o json | jq -r '.items[] | select (.spec.username == "system:serviceaccount:openshift-machine-config-operator:node-bootstrapper")' | jq -r '. | select(.status == {})')
  for CSR_REQUEST in $(echo ${JSON_BODY} | jq -r '. | "\(.metadata.name),\(.spec.request)"')
  do 
    CSR_NAME=$(echo ${CSR_REQUEST} | sed 's|,| |'| awk '{print $1}')
    CSR_REQU=$(echo ${CSR_REQUEST} | sed 's|,| |'| awk '{print $2}')
    echo "CSR_NAME: ${CSR_NAME}"
    NODE_NAME=$(echo ${CSR_REQU} | base64 -d | openssl req -text | grep 'Subject:' | awk '{print $NF}')
    echo "Pending CSR found for NODE_NAME: ${NODE_NAME}"

    if grep -q "system:node:${MACHINE_PREFIX}-" <<< "$NODE_NAME"
    then
      oc adm certificate approve "${CSR_NAME}"
      APPROVED_WORKERS=$(($APPROVED_WORKERS + 1))
    fi
  done

  LOCAL_WORKER_SCAN=0
  while [ "$LOCAL_WORKER_SCAN" -lt "$INTEL_COUNT" ]
  do
    # username: system:node:mac-674e-worker-0
    for CSR_NAME in $(oc get csr -o json | jq -r '.items[] | select (.spec.username == "'system:node:${MACHINE_PREFIX}-${LOCAL_WORKER_SCAN}'")' | jq -r '.metadata.name')
    do
      # Dev note: will approve more than one matching csr
      echo "Approving: ${CSR_NAME} system:node:${MACHINE_PREFIX}-${LOCAL_WORKER_SCAN}"
      oc adm certificate approve "${CSR_NAME}"
    done
    LOCAL_WORKER_SCAN=$(($LOCAL_WORKER_SCAN + 1))
  done

  # End Early... we've checked enough.
  if [ "${IDX}" -eq "120" ]
  then
    echo "Exceeded the wait time for CSRs to be generated - > 60 minutes"
    exit 8
  fi
  IDX=$(($IDX + 1))

  # Wait for 30 seconds before we hammer the system
  echo "Sleeping before re-running - 30 seconds"
  sleep 30

  # Re-read the 'Ready' count
  READY_COUNT=$(oc get nodes -l kubernetes.io/arch=amd64 | grep "${MACHINE_PREFIX}" | grep -v NotReady | grep -c Ready)
done

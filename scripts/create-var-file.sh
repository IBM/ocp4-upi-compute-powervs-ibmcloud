#!/usr/bin/env bash

################################################################
# Copyright 2024 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Helper file to generate the var.tfvars file

# The following environment variables need to be set:
# IC_API_KEY or IBMCLOUD_API_KEY - the ibm cloud api key
# POWERVS_SERVICE_INSTANCE_ID - the workspace instance id
# PUBLIC_KEY_FILE - the path to the public key file
# PRIVATE_KEY_FILE - the path to the private key file
# VPC_NAME - the name of the VPC where worker node gets created

# Requires:
# - Path to id_rsa / id_rsa.pub
# - Command: ibmcloud
# - Command: yq
# - Command: jq

EXPECTED_NODES=$2
if [ -z "${EXPECTED_NODES}" ]
then
    EXPECTED_NODES=1
fi

IBMCLOUD=ibmcloud
if [[ $(type -t ic) == function ]]
then
    IBMCLOUD=ic
else 
    ${IBMCLOUD} plugin install -f power-iaas
fi

if [ ! -z "${1}" ]
then
    IBMCLOUD_HOME_FOLDER="${1}"
    function ic() {
    HOME=${IBMCLOUD_HOME_FOLDER} ibmcloud "$@"
    }
    IBMCLOUD=ic
fi

# format file var.tfvars
create_var_file () {

# API Key check
if [ -z "${IC_API_KEY}" ]
then
    # PowerVS Pattern
    export IC_API_KEY="${IBMCLOUD_API_KEY}"
    if [ -z "${IC_API_KEY}" ]
    then
        echo "ERROR: Should fail.... IC_API_KEY needs to be set"
        return
    fi
fi

# VPC Update

if [ -z "${VPC_NAME}" ]
then
    echo "ERROR: Should fail.... VPC_NAME needs to be set"
    echo "From the newly created or existing VPC"
    return
else
    ibmcloud login --apikey "${IC_API_KEY}"
    VPC_REGION=$(ibmcloud is vpc ${VPC_NAME} --output json | jq -r '.crn' | cut -d ':' -f 6)
    echo "VPC REGION: ${VPC_REGION}" 
fi

# PowerVS Update

if [ -z "${POWERVS_SERVICE_INSTANCE_ID}" ]
then
    echo "ERROR: Should fail.... POWERVS_SERVICE_INSTANCE_ID needs to be set"
    echo "From the newly created workspace"
    return
else
    # PowerVS Service Instance exists
    POWERVS_ZONE=$(${IBMCLOUD} resource service-instances --output json | jq -r '.[] | select(.guid == "'${POWERVS_SERVICE_INSTANCE_ID}'").region_id')
    POWERVS_REGION=$(
        case "$POWERVS_ZONE" in
            ("dal10") echo "dal" ;;
            ("dal12") echo "dal" ;;
            ("us-south") echo "us-south" ;;
            ("wdc06") echo "wdc" ;;
            ("us-east") echo "us-east" ;;
            ("sao01") echo "sao" ;;
            ("tor01") echo "tor" ;;
            ("mon01") echo "mon" ;;
            ("mad01") echo "mad" ;;
            ("eu-de-1") echo "eu-de" ;;
            ("eu-de-2") echo "eu-de" ;;
            ("lon04") echo "lon" ;;
            ("lon06") echo "lon" ;;
            ("syd04") echo "syd" ;;
            ("syd05") echo "syd" ;;
            ("tok04") echo "tok" ;;
            ("osa21") echo "osa" ;;
            (*) echo "$POWERVS_ZONE" ;;
        esac)
    echo "PowerVS REGION: ${POWERVS_REGION}"
    echo "PowerVS ZONE: ${POWERVS_ZONE}"
fi

if [ -z "${PUBLIC_KEY_FILE}" ]
then
    echo "ERROR: PUBLIC KEY FILE is not set"
    return
fi
if [ -z "${PRIVATE_KEY_FILE}" ]
then
    echo "ERROR: PRIVATE KEY FILE is not set"
    return
fi

# copy public/private key files
cp "${PUBLIC_KEY_FILE}" data/id_rsa.pub
cp "${PRIVATE_KEY_FILE}" data/id_rsa

# vpc_skip_ssh_key_create is set, and we need to skip creating it.
${IBMCLOUD} is key-create cicd-key @data/id_rsa.pub || true

# creates the var file
cat << EOFXEOF > data/var.tfvars
################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

### IBM Cloud
ibmcloud_api_key = "${IC_API_KEY}"

# VPC
vpc_name   = "${VPC_NAME}"
vpc_region = "${VPC_REGION}"
vpc_zone   = "<Choose VPC ZONE. e.g. ${VPC_REGION}-1 >"

# PowerVS
powervs_service_instance_id = "${POWERVS_SERVICE_INSTANCE_ID}"
powervs_region              = "${POWERVS_REGION}"
powervs_zone                = "${POWERVS_ZONE}"

# Public and Private Key for Bastion Nodes
public_key_file  = "data/id_rsa.pub"
private_key_file = "data/id_rsa"

# VPC Workers
# Zone 1
worker_1 = { count = "${EXPECTED_NODES}", profile = "cx2-8x16", "zone" = "${VPC_REGION}-1" }
# Zone 2
worker_2 = { count = "0", profile = "cx2-8x16", "zone" = "${VPC_REGION}-2" }
# Zone 3
worker_3 = { count = "0", profile = "cx2-8x16", "zone" = "${VPC_REGION}-3" }

# Required for Ignition and Automation to Run (powervs_bastion_private_ip generally belongs to 192.168.200.x range)
powervs_bastion_private_ip = "<Private IP Address of Bastion>"
powervs_bastion_ip         = "<Public IP Address of Bastion>"
vpc_skip_ssh_key_create = true
EOFXEOF
}

create_var_file

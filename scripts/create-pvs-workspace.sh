#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

IBMCLOUD=ibmcloud
if [[ $(type -t ic) == function ]]
then
    IBMCLOUD=ic
else 
    ibmcloud plugin install -f power-iaas
fi

if [ -z "${WORKSPACE_NAME}" ]
then 
    echo "Failed: no workspace name set"
    return -1
fi

if [ -z "${REGION}" ]
then 
    echo "Failed: no REGION name set"
    return -1
fi

if [ -z "${RESOURCE_GROUP}" ]
then 
    echo "Failed: no RESOURCE_GROUP name set"
    return -1
fi

# Create the service instance
ibmcloud pi workspace create "${WORKSPACE_NAME}" \
    --plan public \
    --datacenter "${REGION}" \
    --json \
    --group "${RESOURCE_GROUP}" 2>&1
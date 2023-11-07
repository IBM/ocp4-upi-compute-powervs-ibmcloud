#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Upload RHCOS to ibmcloud cos and starts an import

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
ibmcloud plugin install -f cloud-internet-services vpc-infrastructure cloud-object-storage is dns cis

# Pin the version to 0.4.9 (v1.0.0 may be incompatible)
ibmcloud plugin install -v 0.4.9 -f power-iaas
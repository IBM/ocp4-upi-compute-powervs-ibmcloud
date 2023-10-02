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
fi

ibmcloud login --apikey "${API_KEY}" -r "${REGION}" -g "${RESOURCE_GROUP}"
ibmcloud plugin install -f cloud-internet-services vpc-infrastructure cloud-object-storage power-iaas is

# Download the RHCOS qcow2
TARGET_DIR=".openshift/image-local"
mkdir -p ${TARGET_DIR}
DOWNLOAD_URL=$(openshift-install coreos print-stream-json | jq -r '.architectures.x86_64.artifacts.ibmcloud.formats."qcow2.gz".disk.location')
TARGET_GZ_FILE=$(echo "${DOWNLOAD_URL}" | sed 's|/| |g' | awk '{print $NF}')
TARGET_FILE=$(echo "${TARGET_GZ_FILE}" | sed 's|.gz||g')
if [ ! -f "${TARGET_FILE}" ]
then
  echo "Downloading from URL - ${DOWNLOAD_URL}"
  cd "${TARGET_DIR}" \
    && curl -o ${TARGET_GZ_FILE} -L "${DOWNLOAD_URL}" \
    && gunzip ${TARGET_GZ_FILE}
    && cd -
fi

# Upload the file
TARGET_KEY=$(echo ${TARGET_FILE} | sed 's|[._]|-|g')
ibmcloud cos --bucket "${NAME_PREFIX}-bucket" \
  --region "${REGION}" \
  --key "${TARGET_KEY}" \
  --file "${TARGET_DIR}/${TARGET_FILE}"
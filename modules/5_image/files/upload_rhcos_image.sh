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
ibmcloud plugin install -f cloud-internet-services vpc-infrastructure cloud-object-storage is

# Pin the version to 0.4.9 (v1.0.0 may be incompatible)
ibmcloud plugin install -v 0.4.9 -f power-iaas

# Download the RHCOS qcow2
TARGET_DIR=".openshift/image-local"
mkdir -p ${TARGET_DIR}

# Dev Note: 
# Originally we used: 
# openshift-install coreos print-stream-json | jq -r '.architectures.x86_64.artifacts.ibmcloud.formats."qcow2.gz".disk.location'
# However, this is not always consistent with the running cluster.
# We now generate the URL - https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.15-9.2/builds/415.92.202309142014-0/x86_64/rhcos-415.92.202309142014-0-ibmcloud.x86_64.qcow2.gz

RHCOS_VERSION="4.15-9.2"
OCP_VERSION="$(oc adm release info -a ~/.openshift/pull-secret -o json | jq -r . | grep v4.15. |  tr -d 'v",' | awk -F '=' '{print $2}')"
if [[ "${OCP_VERSION}" == *"4.15."* ]]
then
  RHCOS_VERSION="4.15-9.2"
elif [[ "${OCP_VERSION}" == *"4.16."* ]]
then
  # the 4.16 is just an example...
  RHCOS_VERSION="4.16-9.3"
elif [[ "${OCP_VERSION}" == *"4.17."* ]]
then
  RHCOS_VERSION="4.17-9.4"
elif [[ "${OCP_VERSION}" == *"4.18."* ]]
then
  RHCOS_VERSION="4.18-9.4"
else
  echo "unrecognized version for RHCOS"
  exit 1
fi

RHCOS_BUILD=$(oc adm release info -a ~/.openshift/pull-secret -o json | jq -r '.displayVersions."machine-os".Version')
DOWNLOAD_URL="https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.15-9.2/builds/${RHCOS_BUILD}/x86_64/rhcos-${RHCOS_BUILD}-ibmcloud.x86_64.qcow2.gz"
TARGET_GZ_FILE=$(echo "${DOWNLOAD_URL}" | sed 's|/| |g' | awk '{print $NF}')
TARGET_FILE=$(echo "${TARGET_GZ_FILE}" | sed 's|.gz||g')

if [ -n "${TARGET_FILE}" ]
then
  echo "Deleting old qcow2 file if exists"
  rm -f ${TARGET_DIR}/${TARGET_FILE}
  echo "Downloading from URL - ${DOWNLOAD_URL}"
  cd "${TARGET_DIR}" \
    && curl -o "${TARGET_GZ_FILE}" -L "${DOWNLOAD_URL}" \
    && gunzip ${TARGET_GZ_FILE} && cd -
fi

# Upload the file to bucket
ibmcloud cos object-put --bucket "${NAME_PREFIX}-mac-intel" --key "${NAME_PREFIX}-rhcos.qcow2" --body "${TARGET_DIR}/${TARGET_FILE}"

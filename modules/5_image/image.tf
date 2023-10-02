################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

resource "ibm_resource_instance" "ibm_resource_instance" {
  name              = "${var.name_prefix}-bucket"
  resource_group_id = data.ibm_resource_group.resource_group.id
  service           = "cloud-object-storage"
  plan              = "smart"
  location          = var.vpc_region
}

resource "null_resource" "upload_rhcos_image" {
  depends_on = [ibm_resource_instance.ibm_resource_instance]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
if [ -z "$(command -v ibmcloud)" ]
then
  echo "ibmcloud CLI doesn't exist, installing"
  curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
fi

ibmcloud login --apikey "${var.ibmcloud_api_key}" -r "${var.vpc_region}" -g "${var.resource_group}"
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
ibmcloud cos --bucket "${var.name_prefix}-bucket" \
  --region "${var.vpc_region}" \
  --key "${TARGET_KEY}" \
  --file "${TARGET_DIR}/${TARGET_FILE}"
EOF
    ]
  }
}

resource "ibm_is_image" "worker_image_id" {
  depends_on = [null_resource.upload_rhcos_image]
  name               = "${var.name_prefix}-img"
  href               = "cos://${var.vpc_region}/${var.name_prefix}-bucket/${var.name_prefix}-rhcos.qcow2"
  operating_system   = "rhel-coreos-stable-amd64"
  resource_group = var.resource_group
  access_tags = [ "mac-intel-worker" ]
}

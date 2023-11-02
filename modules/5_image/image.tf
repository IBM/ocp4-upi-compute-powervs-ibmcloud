################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  intel_image_upload_script_path = "/root/ocp4-upi-compute-powervs-ibmcloud/intel/image"
}

data "ibm_resource_group" "resource_group" {
  name = var.resource_group_name
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.name_prefix}-mac-intel-cos"
  resource_group_id = data.ibm_resource_group.resource_group.id
  # allow_cleanup     = true // automatically decided by the service-broker
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
}

resource "ibm_cos_bucket" "cos_bucket" {
  depends_on           = [ibm_resource_instance.cos_instance]
  bucket_name          = "${var.name_prefix}-mac-intel"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.vpc_region
  storage_class        = "standard"
}

resource "null_resource" "upload_rhcos_image" {
  depends_on = [ibm_cos_bucket.cos_bucket]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ${local.intel_image_upload_script_path}"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/files/upload_rhcos_image.sh"
    destination = "${local.intel_image_upload_script_path}/upload_rhcos_image.sh"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
echo 'Uploading rhcos image to ibmcloud'
cd "${local.intel_image_upload_script_path}"
chmod +x upload_rhcos_image.sh
./upload_rhcos_image.sh "${var.ibmcloud_api_key}" "${var.vpc_region}" "${var.resource_group_name}" "${var.name_prefix}"
echo 'Done with rhcos image uploading to ibmcloud'
EOF
    ]
  }
}

resource "ibm_is_image" "worker_image_id" {
  depends_on       = [null_resource.upload_rhcos_image]
  name             = "${var.name_prefix}-rhcos-img"
  href             = "cos://${var.vpc_region}/${var.name_prefix}-mac-intel/${var.name_prefix}-rhcos.qcow2"
  operating_system = "rhel-coreos-stable-amd64"
  resource_group   = data.ibm_resource_group.resource_group.id

  //increase timeouts as this import may be cross-region
  timeouts {
    create = "45m"
  }
}

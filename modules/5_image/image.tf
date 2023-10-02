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

  provisioner "file" {
    source      = "${path.module}/files/upload_rhcos_image.sh"
    destination = "ocp4-upi-compute/intel/image/upload_rhcos_image.sh"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
echo 'Uploading rhcos image to ibmcloud'
cd ocp4-upi-compute/intel/image/upload_rhcos_image.sh
chmod +x upload_rhcos_image.sh
./upload_rhcos_image.sh "${var.ibmcloud_api_key}" "${var.vpc_region}" "${var.name_prefix}"
echo 'Done with rhcos image uploading to ibmcloud'
EOF
    ]
  }
}

resource "ibm_is_image" "worker_image_id" {
  depends_on       = [null_resource.upload_rhcos_image]
  name             = "${var.name_prefix}-img"
  href             = "cos://${var.vpc_region}/${var.name_prefix}-bucket/${var.name_prefix}-rhcos.qcow2"
  operating_system = "rhel-coreos-stable-amd64"
  resource_group   = var.resource_group
  access_tags      = ["mac-intel-worker"]
}

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  worker_1_count = lookup(var.worker_1, "count", 1)
  worker_1_zone  = lookup(var.worker_1, "zone", "")
  worker_2_count = lookup(var.worker_2, "count", 0)
  worker_2_zone  = lookup(var.worker_2, "zone", "")
  worker_3_count = lookup(var.worker_3, "count", 0)
  worker_3_zone  = lookup(var.worker_3, "zone", "")
}

resource "null_resource" "configure_public_gateway" {
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
      "rm -rf /root/ocp4-upi-compute-powervs-ibmcloud-vpc-gw/",
      "mkdir -p /root/ocp4-upi-compute-powervs-ibmcloud-vpc-gw/"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/files/public_gateway.sh"
    destination = "/root/ocp4-upi-compute-powervs-ibmcloud-vpc-gw/public_gateway.sh"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
cd /root/ocp4-upi-compute-powervs-ibmcloud-vpc-gw

echo "Running the Public Gateway check and setup"
bash public_gateway.sh "${var.ibmcloud_api_key}" "${var.vpc_region}" "${var.resource_group_name}" \
  "${var.vpc_name}" "${var.vpc_create_public_gateways}" \
  "${local.worker_1_count}" "${local.worker_1_zone}" \
  "${local.worker_2_count}" "${local.worker_2_zone}" \
  "${local.worker_3_count}" "${local.worker_3_zone}"
EOF
    ]
  }
}

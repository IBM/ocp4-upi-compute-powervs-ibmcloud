################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  ansible_post_path = "/root/ocp4-upi-compute-powervs-ibmcloud/post"
}

# Dev Note: only on destroy - restore the load balancers
resource "null_resource" "remove_lbs" {

  triggers = {
    count_1             = var.worker_1["count"]
    count_2             = var.worker_2["count"]
    count_3             = var.worker_3["count"]
    user                = var.rhel_username
    timeout             = "${var.connection_timeout}m"
    name_prefix         = "${var.name_prefix}"
    private_key         = sensitive(file(var.private_key_file))
    host                = sensitive(var.bastion_public_ip)
    agent               = var.ssh_agent
    ansible_post_path   = local.ansible_post_path
    ibmcloud_api_key    = sensitive(var.ibmcloud_api_key)
    vpc_region          = var.vpc_region
    resource_group_name = sensitive(var.resource_group_name)
    vpc_name            = sensitive(var.vpc_name)
  }

  connection {
    type        = "ssh"
    user        = self.triggers.user
    private_key = self.triggers.private_key
    host        = self.triggers.host
    agent       = self.triggers.agent
    timeout     = self.triggers.timeout
  }

  provisioner "remote-exec" {
    inline = [<<EOF
mkdir -p /root/ocp4-upi-compute-powervs-ibmcloud/intel/lbs/
EOF
    ]
  }

  provisioner "file" {
    source      = "${path.module}/files/remove_lbs.sh"
    destination = "/root/ocp4-upi-compute-powervs-ibmcloud/intel/lbs/remove_lbs.sh"
  }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [<<EOF
cd /root/ocp4-upi-compute-powervs-ibmcloud/intel/lbs/
bash remove_lbs.sh "${self.triggers.ibmcloud_api_key}" "${self.triggers.vpc_region}" "${self.triggers.resource_group_name}" "${self.triggers.vpc_name}"

EOF
    ]
  }
}

resource "null_resource" "updating_load_balancers" {
  depends_on = [null_resource.remove_lbs]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
mkdir -p /root/ocp4-upi-compute-powervs-ibmcloud/intel/lbs/
EOF
    ]
  }

  provisioner "file" {
    source      = "${path.module}/files/update_lbs.sh"
    destination = "/root/ocp4-upi-compute-powervs-ibmcloud/intel/lbs/update_lbs.sh"
  }

  # Dev Note: Updates the load balancers
  provisioner "remote-exec" {
    inline = [<<EOF
cd /root/ocp4-upi-compute-powervs-ibmcloud/intel/lbs/
bash update_lbs.sh "${var.ibmcloud_api_key}" "${var.vpc_region}" "${var.resource_group_name}" "${var.vpc_name}"
EOF
    ]
  }
}


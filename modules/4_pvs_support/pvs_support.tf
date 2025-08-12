################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  helpernode_inventory = {
    rhel_username = var.rhel_username
  }

  cidrs = {
    cidrs_ipv4 = var.cidrs
    gateway    = cidrhost(var.powervs_machine_cidr, 1)
  }

  cidrs_dyna_iface = {
    cidrs_ipv4 = var.cidrs
    gateway    = cidrhost(var.powervs_machine_cidr, 1)
    bastion_ip = var.ignition_ip
  }
}

resource "null_resource" "setup" {
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
      "rm -rf /root/ocp4-upi-compute-powervs-ibmcloud/intel/",
      "mkdir -p .openshift",
      "mkdir -p /root/ocp4-upi-compute-powervs-ibmcloud/intel/"
    ]
  }

  # Copies the ansible/support to specific folder
  provisioner "file" {
    source      = "ansible/support"
    destination = "/root/ocp4-upi-compute-powervs-ibmcloud/intel/support/"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/templates/inventory.tpl", local.helpernode_inventory)
    destination = "ocp4-upi-compute-powervs-ibmcloud/intel/support/inventory"
  }

  # Copies the custom route for env3
  provisioner "file" {
    content     = templatefile("${path.module}/templates/route-env.sh.tpl", local.cidrs_dyna_iface)
    destination = "ocp4-upi-compute-powervs-ibmcloud/intel/support/route-env.sh"
  }

  # Copies the custom route for env3
  provisioner "file" {
    content     = templatefile("${path.module}/templates/route.env.tpl", local.cidrs)
    destination = "/root/ocp4-upi-compute-powervs-ibmcloud/intel/support/route.env"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
cd ocp4-upi-compute-powervs-ibmcloud/intel/support
bash route-env.sh
EOF
    ]
  }
}

resource "null_resource" "limit_csi_arch" {
  depends_on = [null_resource.setup]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  # Dev Note: Running the following should show you ppc64le
  # ❯ oc get ns openshift-cluster-csi-drivers -oyaml | yq -r '.metadata.annotations' | grep ppc64le
  # scheduler.alpha.kubernetes.io/node-selector: kubernetes.io/arch=ppc64le
  provisioner "remote-exec" {
    inline = [<<EOF
oc annotate ns openshift-cluster-csi-drivers \
  scheduler.alpha.kubernetes.io/node-selector=kubernetes.io/arch=ppc64le
EOF
    ]
  }
}

resource "null_resource" "migrate_mcp" {
  depends_on = [null_resource.limit_csi_arch]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = sensitive(file(var.private_key_file))
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
mkdir -p /root/ocp4-upi-compute-powervs-ibmcloud/intel/migrate-mcp/
EOF
    ]
  }

  provisioner "file" {
    source      = "${path.module}/files/migrate-mcp.sh"
    destination = "/root/ocp4-upi-compute-powervs-ibmcloud/intel/migrate-mcp/migrate-mcp.sh"
  }

  # Dev Note: Creates a worker specific butane configuration
  provisioner "remote-exec" {
    inline = [<<EOF
cd /root/ocp4-upi-compute-powervs-ibmcloud/intel/migrate-mcp/
bash migrate-mcp.sh
EOF
    ]
  }
}

# Dev Note: adjust_mtu comes back if we need to modify the MTU
# resource "null_resource" "adjust_mtu" {
#   depends_on = [null_resource.limit_csi_arch]
#   connection {
#     type        = "ssh"
#     user        = var.rhel_username
#     host        = var.bastion_public_ip
#     private_key = file(var.private_key_file)
#     agent       = var.ssh_agent
#     timeout     = "${var.connection_timeout}m"
#   }
#   provisioner "remote-exec" {
#     inline = [<<EOF
# oc patch Network.operator.openshift.io cluster --type=merge --patch \
#   '{"spec": { "migration": { "mtu": { "network": { "from": 1450, "to": 9000 } , "machine": { "to" : 9100} } } } }'
# EOF
#     ]
#   }
# }

# ovnkube between vpc/powervs requires routingViaHost for the LBs to work properly
# ref: https://community.ibm.com/community/user/powerdeveloper/blogs/mick-tarsel/2023/01/26/routingviahost-with-ovnkuberenetes
resource "null_resource" "set_routing_via_host" {
  depends_on = [null_resource.migrate_mcp]
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
oc patch network.operator/cluster --type merge -p \
  '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"gatewayConfig":{"routingViaHost":true}}}}}'
EOF
    ]
  }
}

# Dev Note: do this as the last step so we get a good worker ignition file downloaded.
resource "null_resource" "latest_ignition" {
  depends_on = [null_resource.set_routing_via_host]
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
echo 'Running ocp4-upi-compute-powervs-ibmcloud playbook for ignition...'
cd ocp4-upi-compute-powervs-ibmcloud/intel/support
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-ibmcloud-support-ignition.log ansible-playbook tasks/ignition.yml --become
EOF
    ]
  }
}

# Dev Note: only on destroy - restore chrony
resource "null_resource" "remove_chrony_changes" {
  depends_on = [null_resource.set_routing_via_host]

  triggers = {
    user        = var.rhel_username
    timeout     = "${var.connection_timeout}m"
    private_key = sensitive(file(var.private_key_file))
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
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
mkdir -p /root/ocp4-upi-compute-powervs-ibmcloud/intel/chrony/
EOF
    ]
  }

  provisioner "file" {
    source      = "${path.module}/files/remove_chrony.sh"
    destination = "/root/ocp4-upi-compute-powervs-ibmcloud/intel/chrony/remove_chrony.sh"
  }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [<<EOF
cd /root/ocp4-upi-compute-powervs-ibmcloud/intel/chrony/
bash remove_chrony.sh
EOF
    ]
  }
}

# Dev Note: do this as the last step so we get a good worker ignition file downloaded.
resource "null_resource" "update_chrony" {
  depends_on = [null_resource.set_routing_via_host, null_resource.remove_chrony_changes]
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
mkdir -p /root/ocp4-upi-compute-powervs-ibmcloud/intel/chrony/
EOF
    ]
  }

  provisioner "file" {
    source      = "${path.module}/files/add_chrony.sh"
    destination = "/root/ocp4-upi-compute-powervs-ibmcloud/intel/chrony/add_chrony.sh"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
cd /root/ocp4-upi-compute-powervs-ibmcloud/intel/chrony/
bash add_chrony.sh
EOF
    ]
  }
}
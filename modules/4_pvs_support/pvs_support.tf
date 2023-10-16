################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  # The Inventory File
  helpernode_inventory = {
    rhel_username = var.rhel_username
  }

  # you must use the api-int url so the bastion routes over the correct interface.
  helpernode_vars = {
    openshift_machine_config_url = replace(var.openshift_api_url, ":6443", "")
  }

  cidrs = {
    cidrs_ipv4 = var.cidrs
    gateway    = cidrhost(var.powervs_machine_cidr, 1)
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
      "rm -rf /root/ocp4-upi-compute/intel/",
      "mkdir -p .openshift",
      "mkdir -p /root/ocp4-upi-compute/intel/"
    ]
  }

  # Copies the ansible/support to specific folder
  provisioner "file" {
    source      = "ansible/support"
    destination = "/root/ocp4-upi-compute/intel/support/"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/templates/inventory.tpl", local.helpernode_inventory)
    destination = "ocp4-upi-compute/intel/support/inventory"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/templates/vars.yaml.tpl", local.helpernode_vars)
    destination = "ocp4-upi-compute/intel/support/vars/vars.yaml"
  }

  # Copies the custom route for env3
  provisioner "file" {
    content     = templatefile("${path.module}/templates/route-env3.tpl", local.cidrs)
    destination = "/etc/sysconfig/network-scripts/route-env3"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
nmcli device up env3

echo 'Running ocp4-upi-compute/intel/ playbook...'
cd ocp4-upi-compute/intel/support
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute/intel/-support.log ansible-playbook -e @vars/vars.yaml tasks/main.yml --become
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

  # Dev Note: Running the following should show you amd64
  # ❯ oc get ns openshift-cluster-csi-drivers -oyaml | yq -r '.metadata.annotations' | grep amd64
  # scheduler.alpha.kubernetes.io/node-selector: kubernetes.io/arch=amd64
  provisioner "remote-exec" {
    inline = [<<EOF
oc annotate --kubeconfig /root/.kube/config ns openshift-cluster-csi-drivers \
  scheduler.alpha.kubernetes.io/node-selector=kubernetes.io/arch=ppc64le
EOF
    ]
  }
}

resource "null_resource" "adjust_mtu" {
  depends_on = [null_resource.limit_csi_arch]
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
oc patch Network.operator.openshift.io cluster --type=merge --patch \
  '{"spec": { "migration": { "mtu": { "network": { "from": 1450, "to": 9000 } , "machine": { "to" : 9100} } } } }'
EOF
    ]
  }
}

# ovnkube between vpc/powervs requires routingViaHost for the LBs to work properly
# ref: https://community.ibm.com/community/user/powerdeveloper/blogs/mick-tarsel/2023/01/26/routingviahost-with-ovnkuberenetes
resource "null_resource" "set_routing_via_host" {
  depends_on = [null_resource.adjust_mtu]
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

resource "null_resource" "wait_on_mcp" {
  depends_on = [null_resource.set_routing_via_host, null_resource.adjust_mtu]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  # Dev Note: added hardening to the MTU wait, we wait for the condition and then fail
  provisioner "remote-exec" {
    inline = [<<EOF
echo "-diagnostics-"
oc get network cluster -o yaml | grep -i mtu
oc get mcp

echo 'verifying worker mc'
start_counter=0
timeout_counter=10
mtu_output=`oc get mc 00-worker -o yaml | grep TARGET_MTU=9100`
echo "(DEBUG) MTU FOUND?: $${mtu_output}"
# While loop waits for TARGET_MTU=9100 till timeout has not reached 
while [[ "$(oc get network cluster -o yaml | grep 'to: 9100' | awk '{print $NF}')" != "9100" ]]
do
  echo "waiting on worker"
  sleep 30
done

RENDERED_CONFIG=$(oc get mcp/worker -o json | jq -r '.spec.configuration.name')
CHECK_CONFIG=$(oc get mc $${RENDERED_CONFIG} -ojson 2>&1 | grep TARGET_MTU=9100)
while [ -z "$${CHECK_CONFIG}" ]
do
  echo "waiting on worker"
  sleep 30
  RENDERED_CONFIG=$(oc get mcp/worker -o json | jq -r '.spec.configuration.name')
  CHECK_CONFIG=$(oc get mc $${RENDERED_CONFIG} -ojson 2>&1 | grep TARGET_MTU=9100)
done

# Waiting on output
oc wait mcp/worker \
  --for condition=updated \
  --timeout=5m || true

echo '-checking mtu-'
oc get network cluster -o yaml | grep 'to: 9100' | awk '{print $NF}'
[[ "$(oc get network cluster -o yaml | grep 'to: 9100' | awk '{print $NF}')" == "9100" ]] || false
echo "success on wait on mtu change"
EOF
    ]
  }
}

# Dev Note: do this as the last step so we get a good worker ignition file downloaded.
resource "null_resource" "latest_ignition" {
  depends_on = [null_resource.wait_on_mcp]
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
nmcli device up env3
echo 'Running ocp4-upi-compute-powervs playbook for ignition...'
cd ocp4-upi-compute-powervs/support
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-support.log ansible-playbook -e @vars/vars.yaml tasks/ignition.yml --become
EOF
    ]
  }
}
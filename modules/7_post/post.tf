################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  ansible_post_path = "/root/ocp4-upi-compute-powervs-ibmcloud/post"
  ansible_vars = {
    region       = var.vpc_region
    zone         = var.vpc_zone
    system_type  = var.worker_1["profile"]
    worker_count = sum([var.worker_1["count"], var.worker_2["count"], var.worker_3["count"]])
  }
}

resource "null_resource" "post_setup" {
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
  }

  #copies the ansible/post to specific folder
  provisioner "file" {
    source      = "ansible/post"
    destination = "${local.ansible_post_path}/"
  }
}

# Dev Note: only on destroy - remove the workers, and leave it at the top after post_setup
resource "null_resource" "remove_workers" {
  depends_on = [null_resource.post_setup]

  triggers = {
    count_1           = var.worker_1["count"]
    count_2           = var.worker_2["count"]
    count_3           = var.worker_3["count"]
    name_prefix       = "${var.name_prefix}"
    private_key       = file(var.private_key_file)
    host              = var.bastion_public_ip
    agent             = var.ssh_agent
    ansible_post_path = local.ansible_post_path
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = self.triggers.private_key
    host        = self.triggers.host
    agent       = self.triggers.agent
  }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [<<EOF
cd ${self.triggers.ansible_post_path}
bash files/destroy-workers.sh "${self.triggers.count_1}" "${self.triggers.count_2}" "${self.triggers.count_3}" "${self.triggers.name_prefix}"
EOF
    ]
  }
}

#Command to run ansible playbook on bastion
resource "null_resource" "post_ansible" {
  depends_on = [null_resource.remove_workers]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
  }

  #create ansible_post_vars.json file on bastion (with desired variables to be passed to Ansible from Terraform)
  provisioner "file" {
    content     = templatefile("${path.module}/templates/ansible_post_vars.json.tpl", local.ansible_vars)
    destination = "${local.ansible_post_path}/ansible_post_vars.json"
  }

  #command to run ansible playbook on Bastion
  provisioner "remote-exec" {
    inline = [<<EOF
echo "Running ansible-playbook for post Intel worker ignition"
cd ${local.ansible_post_path}
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-ibmcloud-post.log ansible-playbook tasks/main.yml --extra-vars @ansible_post_vars.json
EOF
    ]
  }
}

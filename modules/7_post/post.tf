################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  ansible_post_path = "/root/ocp4-upi-compute-powervs-ibmcloud/post"
  worker_count      = sum([var.worker_1["count"], var.worker_2["count"], var.worker_3["count"]])
  ansible_vars = {
    region       = var.vpc_region
    zone         = var.vpc_zone
    system_type  = var.worker_1["profile"]
    worker_count = local.worker_count
  }
}

resource "null_resource" "post_setup" {
  connection {
    type        = "ssh"
    user        = var.rhel_username
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
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
    user              = var.rhel_username
    timeout           = "${var.connection_timeout}m"
    name_prefix       = "${var.name_prefix}"
    private_key       = sensitive(file(var.private_key_file))
    host              = var.bastion_public_ip
    agent             = var.ssh_agent
    ansible_post_path = local.ansible_post_path
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
resource "null_resource" "approve_and_issue" {
  depends_on = [null_resource.remove_workers]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  #create approval script
  provisioner "file" {
    source      = "${path.module}/files/approve_and_issue.sh"
    destination = "${local.ansible_post_path}/approve_and_issue.sh"
  }

  #command to run ansible playbook on Bastion
  provisioner "remote-exec" {
    inline = [<<EOF
echo "Running the CSR approval and issue"
cd ${local.ansible_post_path}
bash approve_and_issue.sh ${var.worker_1["count"]} ${var.name_prefix} "z1"
bash approve_and_issue.sh ${var.worker_2["count"]} ${var.name_prefix} "z2"
bash approve_and_issue.sh ${var.worker_3["count"]} ${var.name_prefix} "z3"
EOF
    ]
  }
}

#Command to run ansible playbook on bastion
resource "null_resource" "post_ansible" {
  depends_on = [null_resource.approve_and_issue]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  #create ansible_post_vars.json file on bastion (with desired variables to be passed to Ansible from Terraform)
  provisioner "file" {
    content     = templatefile("${path.module}/templates/ansible_post_vars.json.tpl", local.ansible_vars)
    destination = "${local.ansible_post_path}/ansible_post_vars.json"
  }

  #command to run ansible playbook on Bastion
  provisioner "remote-exec" {
    inline = [<<EOF
echo "Running ansible-playbook for post Intel worker added to cluster"
cd ${local.ansible_post_path}
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-ibmcloud-post.log ansible-playbook tasks/main.yml --extra-vars @ansible_post_vars.json
EOF
    ]
  }
}

# Dev Note: cleans up the image pruner jobs, which is a problem when there are prior failures.
resource "null_resource" "cleanup_image_pruner" {
  count      = var.cicd_image_pruner_cleanup ? 1 : 0
  depends_on = [null_resource.post_ansible]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  # Dev Note: You may see ImagePrunerDegraded
  # Ref: https://access.redhat.com/solutions/5370391
  provisioner "remote-exec" {
    inline = [<<EOF
if [ $(oc get co image-registry -oyaml | grep -c ImagePrunerDegraded) -ne 0 ]
then
  oc patch imagepruner.imageregistry/cluster --patch '{"spec":{"suspend":true}}' --type=merge
  sleep 15
  oc -n openshift-image-registry delete jobs --all
  sleep 15
  oc patch imagepruner.imageregistry/cluster --patch '{"spec":{"suspend":false}}' --type=merge
fi
EOF
    ]
  }
}

resource "null_resource" "patch_nfs_arch_ppc64le" {
  depends_on = [null_resource.cleanup_image_pruner, null_resource.post_ansible]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  # Dev Note: the original nfs-client-provisioner used gcr.io, and should use the supported path see OCTOPUS-514
  provisioner "remote-exec" {
    inline = [<<EOF
oc patch deployments nfs-client-provisioner -n nfs-provisioner -p '{"spec": {"template": {"spec": {"nodeSelector": {"kubernetes.io/arch": "ppc64le"}}}}}'

if [ $(oc get deployment -n nfs-provisioner -o json | grep -c 'gcr.io/k8s-staging-sig-storage/nfs-subdir-external-provisioner:v4.0.0') -eq 1 ]
then 

oc patch deployments nfs-client-provisioner -n nfs-provisioner --type "json" -p '[
{"op":"remove","path":"/spec/template/spec/containers/0/image"},
{"op":"add","path":"/spec/template/spec/containers/0/image","value":"registry.k8s.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2"}]'

fi
EOF
    ]
  }
}

# Dev Note: we skip this as it implies the CIS, Security Groups and Load Balancers are used
module "haproxy_lb_support" {
  count      = var.ibm_cloud_cis ? 0 : 1
  depends_on = [null_resource.patch_nfs_arch_ppc64le]
  source     = "./haproxy_lb"

  ssh_agent          = var.ssh_agent
  rhel_username      = var.rhel_username
  connection_timeout = var.connection_timeout
  bastion_public_ip  = var.bastion_public_ip
  private_key_file   = var.private_key_file
  vpc_region         = var.vpc_region
  vpc_zone           = var.vpc_zone
  name_prefix        = var.name_prefix
  worker_1           = var.worker_1
  worker_2           = var.worker_2
  worker_3           = var.worker_3
}

# Dev Note: we only execute when CIS, Security Groups and Load Balancers are used
module "ibmcloud_lb_support" {
  count      = var.ibm_cloud_cis ? 1 : 0
  depends_on = [null_resource.patch_nfs_arch_ppc64le]
  source     = "./ibmcloud_lb"

  ssh_agent          = var.ssh_agent
  rhel_username      = var.rhel_username
  connection_timeout = var.connection_timeout
  bastion_public_ip  = var.bastion_public_ip
  private_key_file   = var.private_key_file
  vpc_region         = var.vpc_region
  vpc_zone           = var.vpc_zone
  name_prefix        = var.name_prefix
  worker_1           = var.worker_1
  worker_2           = var.worker_2
  worker_3           = var.worker_3
}
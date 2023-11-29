################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# resource "null_resource" "configure_public_gateway" {
#   connection {
#     type        = "ssh"
#     user        = var.rhel_username
#     host        = var.bastion_public_ip
#     private_key = file(var.private_key_file)
#     agent       = var.ssh_agent
#     timeout     = "${var.connection_timeout}m"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "rm -rf /root/ocp4-upi-compute-powervs-ibmcloud-vpc-setup/",
#       "mkdir -p /root/ocp4-upi-compute-powervs-ibmcloud-vpc-setup/"
#     ]
#   }

#   provisioner "file" {
#     source      = "${path.module}/files/cis.sh"
#     destination = "/root/ocp4-upi-compute-powervs-ibmcloud-vpc-setup/cis.sh"
#   }

#   provisioner "file" {
#     source      = "${path.module}/files/public_gateway.sh"
#     destination = "/root/ocp4-upi-compute-powervs-ibmcloud-vpc-setup/public_gateway.sh"
#   }

#   provisioner "file" {
#     source      = "${path.module}/files/setup.sh"
#     destination = "/root/ocp4-upi-compute-powervs-ibmcloud-vpc-setup/setup.sh"
#   }

#   provisioner "remote-exec" {
#     inline = [<<EOF
# cd /root/ocp4-upi-compute-powervs-ibmcloud-vpc-setup

# echo "Running the ibmcloud setup"
# bash setup.sh

# echo "Running the Public Gateway check and setup"
# bash public_gateway.sh

# echo "Running the cis check and setup"
# bash cis.sh
# EOF
#     ]
#   }
# }

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# resource "null_resource" "public_gateway_setup" {
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

# Dev note: 
# 1 - Destroy - removes any work that's previously been applied using the stored log
# 2 - Create:
# - Searches for the VPC
# - For each one of the possible zones
#    - Check the Subnets in the Zone has a Public Gateway

# ibmcloud is subnets --output json | less   

# ibmcloud is public-gateway-delete 


# ibmcloud is public-gateway-create --resource-group-name --ip
#     ibmcloud is public-gateway-create my-public-gateway my-vpc us-south-1


# data "ibm_is_subnets" "sn" {
#   routing_table_name = data.ibm_is_vpc.vpc.default_routing_table_name
# }

# locals {

# }

# resource "ibm_is_public_gateway" "example" {
#   count = length(data.ibm_is_subnets.subnets.subnets)
#   name  = data.ibm_is_subnets.sn.subnets[count.index]
#   vpc   = ibm_is_vpc.example.id
#   zone  = "eu-gb-1"
# }

# resource "ibm_is_subnet_public_gateway_attachment" "example" {
#   subnet         = ibm_is_subnet.example.id
#   public_gateway = ibm_is_public_gateway.example.id
# }
################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "ssh_agent" {}
variable "connection_timeout" {}
variable "rhel_username" {}
variable "bastion_public_ip" {}
variable "private_key_file" {}
variable "vpc_region" {}
variable "vpc_name" {}
variable "vpc_zone" {}
variable "ibmcloud_api_key" {}
variable "resource_group_name" {}
variable "name_prefix" {}
variable "worker_1" {}
variable "worker_2" {}
variable "worker_3" {}
variable "cicd_image_pruner_cleanup" {}
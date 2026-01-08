################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "ssh_agent" {}
variable "cidrs" {}
variable "powervs_machine_cidr" {}
variable "bastion_public_ip" {}
variable "private_key_file" {}
variable "connection_timeout" {}
variable "rhel_username" {}
variable "ignition_ip" {}
variable "ibmcloud_api_key" {}
variable "vpc_name" {}
variable "vpc_region" {}
variable "resource_group" {}
variable "only_use_worker_mcp" {}
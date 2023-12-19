################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "vpc_create" {}
variable "vpc_name" {}
variable "vpc_region" {}
variable "vpc_zone" {}
variable "vpc_skip_ssh_key_create" {}
variable "public_key_file" {}
variable "public_key" {}
variable "powervs_machine_cidr" {}
variable "resource_group" {}
variable "name_prefix" {}
variable "ibm_cloud_cis" {}

variable "worker_1" {
  type = object({ count = number, profile = string, zone = string })
  default = {
    count   = 1
    profile = "cx2-8x16"
    zone    = ""
  }
  validation {
    condition     = lookup(var.worker_1, "count", 1) >= 1
    error_message = "The worker_1.count value must be greater than 1."
  }
}

variable "worker_2" {
  type = object({ count = number, profile = string, zone = string })
  default = {
    count   = 0
    profile = "cx2-8x16"
    zone    = ""
  }
  validation {
    condition     = lookup(var.worker_2, "count", 1) >= 0
    error_message = "The worker_2.count value must be greater than 0."
  }
}

variable "worker_3" {
  type = object({ count = number, profile = string, zone = string })
  default = {
    count   = 0
    profile = "cx2-8x16"
    zone    = ""
  }
  validation {
    condition     = lookup(var.worker_3, "count", 1) >= 0
    error_message = "The worker_3.count value must be greater than 0."
  }
}
variable "create_custom_subnet" {}

## SSH related
variable "ssh_agent" {}
variable "bastion_public_ip" {}
variable "private_key_file" {}
variable "connection_timeout" {}
variable "rhel_username" {}
variable "skip_create_security_group" {}
variable "skip_route_creation" {}

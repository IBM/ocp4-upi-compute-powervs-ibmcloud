################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# 
variable "ibmcloud_api_key" {}
variable "vpc_region" {}
variable "resource_group_name" {}
variable "vpc_name" {}
variable "vpc_create_public_gateways" {}


## Null Provider
variable "private_key_file" {}
variable "rhel_username" {}
variable "bastion_public_ip" {}
variable "ssh_agent" {}
variable "connection_timeout" {}

## Workers
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
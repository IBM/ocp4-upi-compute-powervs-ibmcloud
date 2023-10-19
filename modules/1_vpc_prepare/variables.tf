################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "vpc_name" {}
variable "vpc_region" {}
variable "vpc_zone" {}
variable "public_key_file" {}
variable "public_key" {}
variable "powervs_machine_cidr" {}
variable "resource_group" {}
#variable "supp_vm_image_name" {
#  type        = string
#  description = "The image name for the support VM."
#  default     = "ibm-centos-stream-9-amd64-4"
#}

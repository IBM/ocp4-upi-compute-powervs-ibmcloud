################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "name_prefix" {}
variable "target_worker_sg_id" {}
#variable "rhcos_image_name" {}
variable "rhcos_image_id" {}
variable "vpc_name" {}
variable "vpc_key_id" {}
variable "ignition_ip" {}


variable "worker_1" {
  type = object({ count = number, profile = string, zone = string })
  default = {
    count   = 1
    profile = "cx2d-8x16"
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
    profile = "cx2d-8x16"
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
    profile = "cx2d-8x16"
    zone    = ""
  }
  validation {
    condition     = lookup(var.worker_3, "count", 1) >= 0
    error_message = "The worker_3.count value must be greater than 0."
  }
}

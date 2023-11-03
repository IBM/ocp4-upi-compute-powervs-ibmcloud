################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "powervs_region" {
  value = var.vpc_create ? var.powervs_region : module.reuse[0].powervs_region
}

output "powervs_zone" {
  value = var.vpc_create ? var.powervs_zone : module.reuse[0].powervs_zone
}

output "vpc_resource_group" {
  value = var.vpc_create ? module.create[0].vpc_resource_group : module.reuse[0].vpc_resource_group
}

output "vpc_resource_group_name" {
  value = var.vpc_create ? module.create[0].vpc_resource_group_name : module.reuse[0].vpc_resource_group_name
}

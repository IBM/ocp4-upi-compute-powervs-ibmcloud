################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "powervs_region" {
  value = local.powervs_region
}

output "powervs_zone" {
  value = local.powervs_zone
}

output "vpc_resource_group" {
  value = data.ibm_is_vpc.ibm_is_vpc.resource_group
}

output "vpc_resource_group_name" {
  value = data.ibm_is_vpc.ibm_is_vpc.resource_group_name
}

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "vpc_resource_group" {
  value = ibm_is_vpc.vpc.resource_group
}

output "vpc_resource_group_name" {
  value = ibm_is_vpc.vpc.resource_group_name
}
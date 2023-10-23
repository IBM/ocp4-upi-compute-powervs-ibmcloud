################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "vpc_check_key" {
  value = local.check_key
}

output "vpc_key_id" {
  value = local.key_id
}

output "vpc_crn" {
  value = data.ibm_is_vpc.vpc.crn
}

output "target_worker_sg_id" {
  value = ibm_is_security_group.worker_vm_sg[0].id
}

output "mac_vpc_subnets" {
  value = data.ibm_is_subnets.vpc_subnets.subnets[*].ipv4_cidr_block
}

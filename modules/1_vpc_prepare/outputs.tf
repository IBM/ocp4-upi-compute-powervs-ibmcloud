################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "vpc_check_key" {
  value = module.keys.vpc_check_key
}

output "vpc_key_id" {
  value = module.keys.vpc_key_id
}

output "vpc_crn" {
  value = data.ibm_is_vpc.vpc.crn
}

output "target_worker_sg_id" {
  value = !var.skip_create_security_group ? module.security_groups.target_worker_sg_id : module.no_security_groups.target_worker_sg_id
}

output "mac_vpc_subnets" {
  value = var.create_custom_subnet ? [ibm_is_subnet.subnet_worker_zone_1[0].ipv4_cidr_block, ibm_is_subnet.subnet_worker_zone_2[0].ipv4_cidr_block, ibm_is_subnet.subnet_worker_zone_3[0].ipv4_cidr_block] : data.ibm_is_subnets.vpc_subnets.subnets[*].ipv4_cidr_block
}

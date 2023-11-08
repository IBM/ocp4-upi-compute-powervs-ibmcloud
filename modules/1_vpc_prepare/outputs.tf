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
  value = local.sg_not_exists == 1 ? ibm_is_security_group.worker_vm_sg[0].id : [for x in data.ibm_is_security_groups.sgs.security_groups : x.id if endswith(x.name, "${var.vpc_name}-workers-sg")][0]
}

output "mac_vpc_subnets" {
  value = var.create_custom_subnet ? [ibm_is_subnet.subnet_worker_zone_1[0].ipv4_cidr_block, ibm_is_subnet.subnet_worker_zone_2[0].ipv4_cidr_block, ibm_is_subnet.subnet_worker_zone_3[0].ipv4_cidr_block] : data.ibm_is_subnets.vpc_subnets.subnets[*].ipv4_cidr_block
}

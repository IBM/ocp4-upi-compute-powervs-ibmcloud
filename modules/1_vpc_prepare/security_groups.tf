################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_is_security_groups" "sgs" {
  vpc_id = data.ibm_is_vpc.vpc.id
}

resource "ibm_is_security_group" "worker_vm_sg" {
  count          = length([for x in data.ibm_is_security_groups.sgs.security_groups : x if endswith(x.name, "${var.vpc_name}-workers-sg")]) == 0 ? 1 : 0
  name           = "${var.vpc_name}-workers-sg"
  vpc            = data.ibm_is_vpc.vpc.id
  resource_group = data.ibm_is_vpc.vpc.resource_group
}

# outbound all
resource "ibm_is_security_group_rule" "worker_all_outbound" {
  count     = length([for x in data.ibm_is_security_groups.sgs.security_groups : x if endswith(x.name, "${var.vpc_name}-workers-sg")]) == 0 ? 1 : 0
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# outbound rule to powervs
resource "ibm_is_security_group_rule" "worker_all_outbound_powervs" {
  count     = length([for x in data.ibm_is_security_groups.sgs.security_groups : x if endswith(x.name, "${var.vpc_name}-workers-sg")]) == 0 ? 1 : 0
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "outbound"
  remote    = var.powervs_machine_cidr
}

# inbound to security group
resource "ibm_is_security_group_rule" "worker_all_sg" {
  count     = length([for x in data.ibm_is_security_groups.sgs.security_groups : x if endswith(x.name, "${var.vpc_name}-workers-sg")]) == 0 ? 1 : 0
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "inbound"
  remote    = ibm_is_security_group.worker_vm_sg[0].id
}

# inbound to cidr
resource "ibm_is_security_group_rule" "worker_all_powervs_cidr" {
  count     = length([for x in data.ibm_is_security_groups.sgs.security_groups : x if endswith(x.name, "${var.vpc_name}-workers-sg")]) == 0 ? 1 : 0
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
}
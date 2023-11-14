################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

resource "ibm_is_security_group" "worker_vm_sg" {
  count = 1
  name           = "${var.vpc_name}-workers-sg"
  vpc            = data.ibm_is_vpc.vpc.id
  resource_group = data.ibm_is_vpc.vpc.resource_group
}

# outbound all
resource "ibm_is_security_group_rule" "worker_all_outbound" {
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# outbound rule to powervs
resource "ibm_is_security_group_rule" "worker_all_outbound_powervs" {
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "outbound"
  remote    = var.powervs_machine_cidr
}

# inbound to security group
resource "ibm_is_security_group_rule" "worker_all_sg" {
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "inbound"
  remote    = ibm_is_security_group.worker_vm_sg[0].id
}

# inbound to cidr
resource "ibm_is_security_group_rule" "worker_all_powervs_cidr" {
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
}
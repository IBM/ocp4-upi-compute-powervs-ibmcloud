################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Loads the VPC Security Groups so we can find the existing ids
# Ref: https://github.com/openshift/installer/blob/master/data/data/ibmcloud/network/vpc/security-groups.tf#L142
data "ibm_is_security_groups" "sgs" {
  vpc_id = data.ibm_is_vpc.vpc.id
}

locals {
  sg_matches    = [for x in data.ibm_is_security_groups.sgs.security_groups : x if endswith(x.name, "${var.vpc_name}-workers-sg")]
  sg_not_exists = length(local.sg_matches) == 0 ? 1 : 0
}

resource "ibm_is_security_group" "worker_vm_sg" {
  count          = var.vpc_create || var.create_custom_subnet ? 1 : local.sg_not_exists
  name           = "${var.vpc_name}-workers-sg"
  vpc            = data.ibm_is_vpc.vpc.id
  resource_group = data.ibm_is_vpc.vpc.resource_group
}

# outbound all
resource "ibm_is_security_group_rule" "worker_all_outbound" {
  count     = var.vpc_create || var.create_custom_subnet ? 1 : local.sg_not_exists
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# outbound rule to powervs
resource "ibm_is_security_group_rule" "worker_all_outbound_powervs" {
  count     = var.vpc_create || var.create_custom_subnet ? 1 : local.sg_not_exists
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "outbound"
  remote    = var.powervs_machine_cidr
}

# inbound to security group
resource "ibm_is_security_group_rule" "worker_all_sg" {
  count     = var.vpc_create || var.create_custom_subnet ? 1 : local.sg_not_exists
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "inbound"
  remote    = ibm_is_security_group.worker_vm_sg[0].id
}

# inbound to cidr
resource "ibm_is_security_group_rule" "worker_all_powervs_cidr" {
  count     = var.vpc_create || var.create_custom_subnet ? 1 : local.sg_not_exists
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
}
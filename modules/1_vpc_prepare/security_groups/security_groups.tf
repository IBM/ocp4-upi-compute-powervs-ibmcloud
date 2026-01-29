################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_is_security_groups" "supp_vm_sgs" {
  vpc_id = var.vpc_id
}

locals {
  sgs = [for x in data.ibm_is_security_groups.supp_vm_sgs.security_groups : x.id if x.name == "${var.vpc_name}-workers-sg"]
}

resource "ibm_is_security_group" "worker_vm_sg" {
  count          = 1
  name           = "${var.vpc_name}-workers-sg"
  vpc            = var.vpc_id
  resource_group = var.vpc_resource_group
  lifecycle {
    ignore_changes = all
  }
}

# outbound all
resource "ibm_is_security_group_rule" "worker_all_outbound" {
  count     = 1
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  lifecycle {
    ignore_changes = all
  }
}

# outbound rule to powervs
resource "ibm_is_security_group_rule" "worker_all_outbound_powervs" {
  count     = 1
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "outbound"
  remote    = var.powervs_machine_cidr
  lifecycle {
    ignore_changes = all
  }
}

# inbound to security group
resource "ibm_is_security_group_rule" "worker_all_sg" {
  count     = 1
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "inbound"
  remote    = ibm_is_security_group.worker_vm_sg[0].id
  lifecycle {
    ignore_changes = all
  }
}

# inbound to cidr
resource "ibm_is_security_group_rule" "worker_all_powervs_cidr" {
  count     = 1
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  lifecycle {
    ignore_changes = all
  }
}

locals {
  lbs_sg = [for x in data.ibm_is_security_groups.supp_vm_sgs.security_groups : x if endswith(x.name, "-ocp-sec-group")]
}

# TCP Inbound 80 - Security group *ocp-sec-group
# Dev Note: Only opens to the Load Balancers SG
# If it exists, it implies that the SG needs to be updated.
resource "ibm_is_security_group_rule" "lbs_to_workers_http" {
  count     = 1
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "inbound"
  remote    = local.lbs_sg[0].id
  protocol  = "tcp"
  port_min  = 80
  port_max  = 80
}

# TCP Inbound 443 - Security group *ocp-sec-group
resource "ibm_is_security_group_rule" "lbs_to_workers_https" {
  count     = 1
  group     = ibm_is_security_group.worker_vm_sg[0].id
  direction = "inbound"
  remote    = local.lbs_sg[0].id
  protocol  = "tcp"
  port_min  = 443
  port_max  = 443
}

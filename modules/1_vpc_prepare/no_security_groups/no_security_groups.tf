################################################################
# Copyright 2025 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_is_security_groups" "supp_vm_sgs" {
  vpc_id = var.vpc_id
}

locals {
  lbs_sg = [for x in data.ibm_is_security_groups.supp_vm_sgs.security_groups : x if endswith(x.name, "-ocp-sec-group")]
}

# depends_on is needed to ensure we're not hitting this before it's possibly created.
data "ibm_security_group" "workers_sg" {
  name = "${var.vpc_name}-workers-sg"
}

# Security Group already exists
# TCP Inbound 80 - Security group *ocp-sec-group
# Dev Note: Only opens to the Load Balancers SG
# If it exists, it implies that the SG needs to be updated.
resource "ibm_is_security_group_rule" "exists_lbs_to_workers_http" {
  count     = 1
  group     = data.ibm_security_group.workers_sg.id
  direction = "inbound"
  remote    = local.lbs_sg[0].id
  protocol  = "tcp"
  port_min  = 80
  port_max  = 80
}

# TCP Inbound 443 - Security group *ocp-sec-group
resource "ibm_is_security_group_rule" "exists_lbs_to_workers_https" {
  count     = 1
  group     = data.ibm_security_group.workers_sg.id
  direction = "inbound"
  remote    = local.lbs_sg[0].id
  protocol  = "tcp"
  port_min  = 443
  port_max  = 443
}
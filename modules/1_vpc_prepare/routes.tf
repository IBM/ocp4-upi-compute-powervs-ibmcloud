################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_is_vpc_routing_tables" "rts" {
  vpc = data.ibm_is_vpc.vpc.id
}

locals {
  rt_matches = [for rt in data.ibm_is_vpc_routing_tables.rts.routing_tables : rt if endswith(rt.name, "to-powervs-route-1")]
  rt_exists  = length(local.sg_matches) > 0 ? 0 : 1
}

resource "ibm_is_vpc_routing_table_route" "route_to_powervs" {
  count         = var.vpc_create || var.create_custom_subnet ? 1 : local.rt_exists
  vpc           = data.ibm_is_vpc.vpc.id
  routing_table = data.ibm_is_vpc.vpc.default_routing_table
  zone          = var.vpc_create || var.create_custom_subnet ? ibm_is_subnet.subnet_worker_zone_1[0].zone : data.ibm_is_vpc.vpc.subnets[0].zone
  name          = "to-powervs-route-1"
  destination   = var.powervs_machine_cidr
  action        = "delegate_vpc"
  next_hop      = "0.0.0.0"
}
################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Condition 1: Transit Gateway Does Not Exist
# Ref: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/tg_gateway
resource "ibm_tg_gateway" "mac_tg_gw" {
  name           = "${var.vpc_name}-tg"
  location       = var.vpc_region
  global         = true
  resource_group = data.ibm_is_vpc.vpc.resource_group
}

# Ref: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/tg_connection
resource "ibm_tg_connection" "vpc_tg_connection" {
  depends_on = [ibm_tg_gateway.mac_tg_gw]
  gateway      = ibm_tg_gateway.mac_tg_gw[0].id
  network_type = "vpc"
  name         = "${var.vpc_name}-vpc-conn"
  network_id   = data.ibm_is_vpc.vpc.resource_crn
}

data "ibm_dl_gateway" "pvs_dl" {
  depends_on = [ibm_tg_connection.vpc_tg_connection]
  name = "mac-cloud-conn-${var.cluster_id}"
}

resource "ibm_tg_connection" "powervs_ibm_tg_connection" {
  depends_on = [data.ibm_dl_gateway.pvs_dl]
  gateway      = ibm_tg_gateway.mac_tg_gw.id
  network_type = "directlink"
  name         = "${var.vpc_name}-pvs-conn"
  network_id   = data.ibm_dl_gateway.pvs_dl.crn
}
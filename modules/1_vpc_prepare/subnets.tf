################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_is_subnets" "vpc_subnets" {
  routing_table_name = data.ibm_is_vpc.vpc.default_routing_table_name
}

resource "ibm_is_vpc_address_prefix" "address_prefix_worker_zone_1" {
  count = var.create_custom_subnet ? 1 : 0
  cidr  = "10.0.1.0/24"
  name  = "worker-zone-1-add-prefix"
  vpc   = data.ibm_is_vpc.vpc.id
  zone  = var.worker_1["zone"]
}

resource "ibm_is_subnet" "subnet_worker_zone_1" {
  count = var.create_custom_subnet ? 1 : 0
  depends_on = [
    ibm_is_vpc_address_prefix.address_prefix_worker_zone_1
  ]
  ipv4_cidr_block = "10.0.1.0/24"
  name            = "worker-zone-1-subnet"
  vpc             = data.ibm_is_vpc.vpc.id
  zone            = var.worker_1["zone"]
}

resource "ibm_is_vpc_address_prefix" "address_prefix_worker_zone_2" {
  count = var.create_custom_subnet ? 1 : 0
  cidr  = "10.0.2.0/24"
  name  = "worker-zone-2-add-prefix"
  vpc   = data.ibm_is_vpc.vpc.id
  zone  = var.worker_2["zone"]
}

resource "ibm_is_subnet" "subnet_worker_zone_2" {
  count = var.create_custom_subnet ? 1 : 0
  depends_on = [
    ibm_is_vpc_address_prefix.address_prefix_worker_zone_2
  ]
  ipv4_cidr_block = "10.0.2.0/24"
  name            = "worker-zone-2-subnet"
  vpc             = data.ibm_is_vpc.vpc.id
  zone            = var.worker_2["zone"]
}

resource "ibm_is_vpc_address_prefix" "address_prefix_worker_zone_3" {
  count = var.create_custom_subnet ? 1 : 0
  cidr  = "10.0.3.0/24"
  name  = "worker-zone-2-add-prefix"
  vpc   = data.ibm_is_vpc.vpc.id
  zone  = var.worker_3["zone"]
}

resource "ibm_is_subnet" "subnet_worker_zone_3" {
  count = var.create_custom_subnet ? 1 : 0
  depends_on = [
    ibm_is_vpc_address_prefix.address_prefix_worker_zone_3
  ]
  ipv4_cidr_block = "10.0.3.0/24"
  name            = "worker-zone-2-subnet"
  vpc             = data.ibm_is_vpc.vpc.id
  zone            = var.worker_3["zone"]
}
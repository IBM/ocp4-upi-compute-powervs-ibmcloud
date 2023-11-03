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

### Zone 1
resource "ibm_is_subnet" "subnet_worker_zone_1" {
  count = var.create_custom_subnet ? 1 : 0
  depends_on = [
    ibm_is_vpc_address_prefix.address_prefix_worker_zone_1
  ]
  ipv4_cidr_block = "10.0.1.0/24"
  name            = "worker-zone-1-subnet"
  vpc             = data.ibm_is_vpc.vpc.id
  zone            = var.worker_1["zone"]
  resource_group  = data.ibm_is_vpc.vpc.resource_group
}

resource "ibm_is_public_gateway" "pg_worker_zone_1" {
  count = var.create_custom_subnet ? 1 : 0
  depends_on = [
    ibm_is_subnet.subnet_worker_zone_1
  ]
  name = "pg-worker-zone-1"
  vpc  = data.ibm_is_vpc.vpc.id
  zone = var.worker_1["zone"]

  timeouts {
    create = "10m"
  }
}

resource "ibm_is_subnet_public_gateway_attachment" "attach_pg_worker_zone_1" {
  count = var.create_custom_subnet ? 1 : 0
  depends_on = [
    ibm_is_public_gateway.pg_worker_zone_1
  ]
  subnet         = ibm_is_subnet.subnet_worker_zone_1[0].id
  public_gateway = ibm_is_public_gateway.pg_worker_zone_1[0].id
}

### Zone 2

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
  resource_group  = data.ibm_is_vpc.vpc.resource_group
}

resource "ibm_is_public_gateway" "pg_worker_zone_2" {
  count = var.create_custom_subnet ? 1 : 0
  depends_on = [
    ibm_is_subnet.subnet_worker_zone_2
  ]
  name = "pg-worker-zone-2"
  vpc  = data.ibm_is_vpc.vpc.id
  zone = var.worker_2["zone"]

  timeouts {
    create = "10m"
  }
}

resource "ibm_is_subnet_public_gateway_attachment" "attach_pg_worker_zone_2" {
  count = var.create_custom_subnet ? 1 : 0
  depends_on = [
    ibm_is_public_gateway.pg_worker_zone_2
  ]
  subnet         = ibm_is_subnet.subnet_worker_zone_2[0].id
  public_gateway = ibm_is_public_gateway.pg_worker_zone_2[0].id
}

### Zone 3
resource "ibm_is_vpc_address_prefix" "address_prefix_worker_zone_3" {
  count = var.create_custom_subnet ? 1 : 0
  cidr  = "10.0.3.0/24"
  name  = "worker-zone-3-add-prefix"
  vpc   = data.ibm_is_vpc.vpc.id
  zone  = var.worker_3["zone"]
}

resource "ibm_is_subnet" "subnet_worker_zone_3" {
  count = var.create_custom_subnet ? 1 : 0
  depends_on = [
    ibm_is_vpc_address_prefix.address_prefix_worker_zone_3
  ]
  ipv4_cidr_block = "10.0.3.0/24"
  name            = "worker-zone-3-subnet"
  vpc             = data.ibm_is_vpc.vpc.id
  zone            = var.worker_3["zone"]
  resource_group  = data.ibm_is_vpc.vpc.resource_group
}

resource "ibm_is_public_gateway" "pg_worker_zone_3" {
  count = var.create_custom_subnet ? 1 : 0
  depends_on = [
    ibm_is_subnet.subnet_worker_zone_3
  ]
  name = "pg-worker-zone-3"
  vpc  = data.ibm_is_vpc.vpc.id
  zone = var.worker_3["zone"]

  timeouts {
    create = "10m"
  }
}

resource "ibm_is_subnet_public_gateway_attachment" "attach_pg_worker_zone_3" {
  count = var.create_custom_subnet ? 1 : 0
  depends_on = [
    ibm_is_public_gateway.pg_worker_zone_3
  ]
  subnet         = ibm_is_subnet.subnet_worker_zone_3[0].id
  public_gateway = ibm_is_public_gateway.pg_worker_zone_3[0].id
}
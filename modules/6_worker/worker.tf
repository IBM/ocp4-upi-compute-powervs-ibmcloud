################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Creates an Intel VSI for the VPC and PowerVS workers 
# Ref: https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/dns/dns.tf

data "ibm_is_vpc" "vpc" {
  name = var.vpc_name
}

data "ibm_is_subnets" "vpc_subnets" {
  routing_table_name = data.ibm_is_vpc.vpc.default_routing_table_name
}

# Dev Note: greedy search for the first matching subnet that uses the worker_1's zone.
locals {
  vpc_subnet_id    = var.create_custom_subnet == true ? data.ibm_is_subnets.vpc_subnets.subnets[0].id : data.ibm_is_vpc.vpc.subnets[0].id
  subnet_for_zone1 = [for subnet in data.ibm_is_subnets.vpc_subnets.subnets : subnet.id if subnet.zone == var.worker_1["zone"]]
  subnet_for_zone2 = [for subnet in data.ibm_is_subnets.vpc_subnets.subnets : subnet.id if subnet.zone == var.worker_2["zone"]]
  subnet_for_zone3 = [for subnet in data.ibm_is_subnets.vpc_subnets.subnets : subnet.id if subnet.zone == var.worker_3["zone"]]
}

resource "ibm_is_instance" "workers_1" {
  count          = var.worker_1["count"]
  name           = "${var.name_prefix}-worker-z1-${count.index}"
  vpc            = data.ibm_is_vpc.vpc.id
  zone           = var.worker_1["zone"]
  keys           = [var.vpc_key_id]
  image          = var.rhcos_image_id
  profile        = var.worker_1["profile"]
  resource_group = data.ibm_is_vpc.vpc.resource_group

  primary_network_interface {
    subnet = local.subnet_for_zone1[0]
    # local.vpc_subnet_id
    security_groups = [var.target_worker_sg_id]
  }

  user_data = templatefile(
    "${path.cwd}/modules/6_worker/templates/worker.ign",
    {
      ignition_ip : var.ignition_ip,
  })
}

resource "ibm_is_instance" "workers_2" {
  count          = var.worker_2["count"]
  name           = "${var.name_prefix}-worker-z2-${count.index}"
  vpc            = data.ibm_is_vpc.vpc.id
  zone           = var.worker_2["zone"]
  keys           = [var.vpc_key_id]
  image          = var.rhcos_image_id
  profile        = var.worker_2["profile"]
  resource_group = data.ibm_is_vpc.vpc.resource_group

  primary_network_interface {
    subnet          = local.subnet_for_zone2[0]
    security_groups = [var.target_worker_sg_id]
  }

  user_data = templatefile(
    "${path.cwd}/modules/6_worker/templates/worker.ign",
    {
      ignition_ip : var.ignition_ip,
  })
}

resource "ibm_is_instance" "workers_3" {
  count          = var.worker_3["count"]
  name           = "${var.name_prefix}-worker-z3-${count.index}"
  vpc            = data.ibm_is_vpc.vpc.id
  zone           = var.worker_3["zone"]
  keys           = [var.vpc_key_id]
  image          = var.rhcos_image_id
  profile        = var.worker_3["profile"]
  resource_group = data.ibm_is_vpc.vpc.resource_group

  primary_network_interface {
    subnet          = local.subnet_for_zone3[0]
    security_groups = [var.target_worker_sg_id]
  }

  user_data = templatefile(
    "${path.cwd}/modules/6_worker/templates/worker.ign",
    {
      ignition_ip : var.ignition_ip,
  })
}

# Waiting for Intel instances to start
resource "time_sleep" "wait_a_few_minutes" {
  depends_on      = [ibm_is_instance.workers_1, ibm_is_instance.workers_2, ibm_is_instance.workers_3]
  create_duration = "3m"
}

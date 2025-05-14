################################################################
# Copyright 2025 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# This branches the logic so they are independently executed and not jointly executed.

module "security_groups" {
  count = !var.skip_create_security_group ? 1 : 0
  providers = {
    ibm = ibm
  }

  source = "./security_groups"

  vpc_resource_group   = data.ibm_is_vpc.vpc.resource_group
  vpc_id               = data.ibm_is_vpc.vpc.id
  vpc_name             = var.vpc_name
  powervs_machine_cidr = var.powervs_machine_cidr
}

module "no_security_groups" {
  count = var.skip_create_security_group ? 1 : 0
  providers = {
    ibm = ibm
  }

  source = "./no_security_groups"

  vpc_id               = data.ibm_is_vpc.vpc.id
  vpc_name             = var.vpc_name
  powervs_machine_cidr = var.powervs_machine_cidr
}
################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

module "keys" {
  source = "./keys"

  providers = {
    ibm = ibm
  }

  public_key_file      = var.public_key_file
  public_key           = var.public_key
  vpc_name             = var.vpc_name
  vpc_create           = var.vpc_create
  create_custom_subnet = var.create_custom_subnet
  vpc_resource_group   = data.ibm_is_vpc.vpc.resource_group
  vpc_skip_ssh_key_create = var.vpc_skip_ssh_key_create
}
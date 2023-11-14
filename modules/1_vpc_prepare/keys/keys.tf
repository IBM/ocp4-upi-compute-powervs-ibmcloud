################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Dev Note: The count value depends on resource warning is take care of through the `var.vpc_skip_ssh_key_create`
# the reason the code is packed in a module is trying to organize the code arround the error.

module "check" {
  providers = {
    ibm = ibm
  }

  source = "./check"

  public_key_file    = var.public_key_file
  public_key         = var.public_key
  vpc_name           = var.vpc_name
  vpc_resource_group = var.vpc_resource_group
}

module "create_new" {
  depends_on = [ module.check ]
  providers = {
    ibm = ibm
  }

  source = "./create_new"

  public_key_file    = var.public_key_file
  public_key         = var.public_key
  vpc_name           = var.vpc_name
  vpc_resource_group = var.vpc_resource_group
  name_prefix = var.name_prefix
}
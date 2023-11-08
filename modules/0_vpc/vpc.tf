################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Ref: VPC Regions https://cloud.ibm.com/docs/overview?topic=overview-locations
# Ref: PowerVS Regions https://cloud.ibm.com/docs/power-iaas?topic=power-iaas-creating-power-virtual-server
# Ref: https://cluster-api-ibmcloud.sigs.k8s.io/reference/regions-zones-mapping.html

# Dev Note: This is the file where the VPC should be created in the future.
# The code should follow the checks, and conditionally create the vpc.
# outputs need to be updated and passed back to the user.

module "reuse" {
  count = var.vpc_create ? 0 : 1
  providers = {
    ibm = ibm
  }
  source = "./reuse"

  ibmcloud_api_key      = var.ibmcloud_api_key
  vpc_name              = var.vpc_name
  vpc_region            = var.vpc_region
  vpc_zone              = var.vpc_zone
  powervs_region        = var.powervs_region
  powervs_zone          = var.powervs_zone
  override_region_check = var.override_region_check
}


### create
module "create" {
  count = var.vpc_create ? 1 : 0
  providers = {
    ibm = ibm
  }
  source = "./create"

  vpc_name           = var.vpc_name
  vpc_resource_group = var.vpc_resource_group
}
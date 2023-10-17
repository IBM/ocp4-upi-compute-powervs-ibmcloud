################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.vpc_region
  zone             = var.vpc_zone
  alias            = "vpc"
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = module.vpc.powervs_region
  zone             = module.vpc.powervs_zone
  alias            = "powervs"
}

# Create a random_id label
# Since we use the hex, the word length would double
resource "random_id" "label" {
  count       = 1
  byte_length = "2"
}

locals {
  cluster_id = var.cluster_id == "" ? random_id.label[0].hex : (var.cluster_id_prefix == "" ? var.cluster_id : "${var.cluster_id_prefix}-${var.cluster_id}")
  # Generates vm_id as combination of vm_id_prefix + (random_id or user-defined vm_id)
  name_prefix = var.name_prefix == "" ? "mac-${random_id.label[0].hex}" : "${var.name_prefix}"
  node_prefix = var.use_zone_info_for_names ? "${var.powervs_zone}-" : ""
}

### Prepares the VPC Support Machine
module "vpc" {
  providers = {
    ibm = ibm.vpc
  }
  source = "./modules/0_vpc"

  ibmcloud_api_key      = var.ibmcloud_api_key
  vpc_name              = var.vpc_name
  vpc_region            = var.vpc_region
  vpc_zone              = var.vpc_zone
  powervs_region        = var.powervs_region
  powervs_zone          = var.powervs_zone
  override_region_check = var.override_region_check
}

### Prepares the VPC Support Machine
module "vpc_prepare" {
  providers = {
    ibm = ibm.vpc
  }
  depends_on = [module.vpc]
  source     = "./modules/1_vpc_prepare"

  vpc_name        = var.vpc_name
  vpc_region      = var.vpc_region
  vpc_zone        = var.vpc_zone
  resource_group  = module.vpc.vpc_resource_group
  public_key      = var.public_key
  public_key_file = var.public_key_file
  #  key_id             = module.vpc_prepare.key_id
  powervs_machine_cidr = var.powervs_machine_cidr
}
/*
module "transit_gateway" {
  providers = {
    ibm = ibm.vpc
  }
  depends_on = [module.vpc_prepare]
  source     = "./modules/3_transit_gateway"

  cluster_id     = local.cluster_id
  vpc_name       = var.vpc_name
  vpc_crn        = module.vpc_prepare.vpc_crn
  vpc_region     = var.vpc_region
  resource_group = module.vpc.vpc_resource_group
}
*/
module "support" {
  providers = {
    ibm = ibm.powervs
  }
  depends_on = [module.vpc_prepare]
  #depends_on = [module.transit_gateway]
  source = "./modules/4_pvs_support"

  private_key_file     = var.private_key_file
  ssh_agent            = var.ssh_agent
  connection_timeout   = var.connection_timeout
  rhel_username        = var.rhel_username
  bastion_public_ip    = var.powervs_bastion_ip
  openshift_api_url    = var.openshift_api_url
  cidrs                = module.vpc_prepare.mac_vpc_subnets
  powervs_machine_cidr = var.powervs_machine_cidr
}

module "image" {
  providers = {
    ibm = ibm.vpc
  }
  depends_on = [module.support]
  source     = "./modules/5_image"

  name_prefix         = local.name_prefix
  vpc_region          = var.vpc_region
  rhel_username       = var.rhel_username
  bastion_public_ip   = var.powervs_bastion_ip
  private_key_file    = var.private_key_file
  ssh_agent           = var.ssh_agent
  connection_timeout  = var.connection_timeout
  ibmcloud_api_key    = var.ibmcloud_api_key
  resource_group_name = module.vpc.vpc_resource_group_name
}

module "worker" {
  providers = {
    ibm = ibm.vpc
  }
  depends_on = [module.image]
  source     = "./modules/6_worker"

  worker_1            = var.worker_1
  worker_2            = var.worker_2
  worker_3            = var.worker_3
  name_prefix         = local.name_prefix
  rhcos_image_id      = module.image.rhcos_image_id
  vpc_name            = var.vpc_name
  vpc_key_id          = module.vpc_prepare.vpc_key_id
  ignition_ip         = var.powervs_bastion_private_ip
  target_worker_sg_id = module.vpc_prepare.target_worker_sg_id
}

module "post" {
  depends_on = [module.worker]
  source     = "./modules/7_post"

  ssh_agent         = var.ssh_agent
  bastion_public_ip = var.powervs_bastion_ip
  private_key_file  = var.private_key_file
  vpc_region        = var.vpc_region
  vpc_zone          = var.vpc_zone
  name_prefix       = local.name_prefix
  worker_1          = var.worker_1
  worker_2          = var.worker_2
  worker_3          = var.worker_3
}

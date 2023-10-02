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
  region           = module.checks.powervs_region
  zone             = module.checks.powervs_zone
  alias            = "powervs"
}

# Create a random_id label
resource "random_id" "label" {
  count       = 1
  byte_length = "2" # Since we use the hex, the word lenght would double
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

  vpc_name             = var.vpc_name
  vpc_region           = var.vpc_region
  vpc_zone             = var.vpc_zone
  public_key           = var.public_key
  public_key_file      = var.public_key_file
  openshift_api_url    = var.openshift_api_url
  powervs_machine_cidr = var.powervs_machine_cidr
  vpc_supp_public_ip   = var.vpc_supp_public_ip
}

module "transit_gateway" {
  providers = {
    ibm = ibm.vpc
  }
  depends_on = [module.vpc_prepare]
  source     = "./modules/2_transit_gateway"

  cluster_id         = local.cluster_id
  vpc_name           = var.vpc_name
  vpc_crn            = module.vpc_support.vpc_crn
  transit_gateway_id = module.vpc_support.transit_gateway_id
}

module "support" {
  providers = {
    ibm = ibm.powervs
  }
  depends_on = [module.transit_gateway]
  source     = "./modules/3_pvs_support"

  private_key_file         = var.private_key_file
  ssh_agent                = var.ssh_agent
  connection_timeout       = var.connection_timeout
  rhel_username            = var.rhel_username
  bastion_public_ip        = var.powervs_bastion_ip
  openshift_client_tarball = var.openshift_client_tarball
  vpc_support_server_ip    = module.vpc_support.vpc_support_server_ip
  openshift_api_url        = var.openshift_api_url
  openshift_user           = var.openshift_user
  openshift_pass           = var.openshift_pass
  kubeconfig_file          = var.kubeconfig_file
  cidrs                    = module.transit_gateway.mac_vpc_subnets
  powervs_machine_cidr     = var.powervs_machine_cidr
}

module "worker" {
  providers = {
    ibm = ibm.powervs
  }
  depends_on = [module.support]
  source     = "./modules/4_worker"

  key_name                    = module.pvs_prepare.pvs_pubkey_name
  name_prefix                 = local.name_prefix
  powervs_service_instance_id = var.powervs_service_instance_id
  powervs_dhcp_network_id     = module.pvs_prepare.powervs_dhcp_network_id
  powervs_dhcp_network_name   = module.pvs_prepare.powervs_dhcp_network_name
  processor_type              = var.processor_type
  rhcos_image_id              = module.pvs_prepare.rhcos_image_id
  system_type                 = var.system_type
  worker                      = var.worker
  ignition_ip                 = module.vpc_prepare.vpc_bootstrap_private_ip
}

module "post" {
  depends_on = [module.worker]
  source     = "./modules/5_post"

  ssh_agent         = var.ssh_agent
  bastion_public_ip = var.powervs_bastion_ip
  private_key_file  = var.private_key_file
  powervs_region    = module.vpc.powervs_region
  powervs_zone      = module.vpc.powervs_zone
  system_type       = var.system_type
  nfs_server        = var.powervs_bastion_ip
  nfs_path          = var.nfs_path
  name_prefix       = local.name_prefix
  worker            = var.worker
}

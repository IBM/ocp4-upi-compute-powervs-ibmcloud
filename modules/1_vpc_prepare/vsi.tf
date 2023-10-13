################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Creates a Support Machine for the VPC and PowerVS integration
# This system is ONLY used for ignition
# Ref: https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/dns/dns.tf

data "ibm_is_image" "supp_vm_image" {
  count = 1
  name  = var.supp_vm_image_name
}

resource "ibm_is_instance" "supp_vm_vsi" {
  count = 1

  name    = "ignition-supp-vsi"
  vpc     = data.ibm_is_vpc.vpc.id
  zone    = var.vpc_zone
  keys    = [local.key_id]
  image   = data.ibm_is_image.supp_vm_image[0].id
  profile = "cx2d-8x16"
  # Profiles: https://cloud.ibm.com/docs/vpc?topic=vpc-profiles&interface=ui
  # Originally used cx2-2x4, however 8x16 includes 300G storage.

  resource_group = data.ibm_is_vpc.vpc.resource_group

  primary_network_interface {
    subnet          = data.ibm_is_subnets.vpc_subnets.subnets[0].id
    security_groups = [ibm_is_security_group.worker_vm_sg.id]
  }

  user_data = templatefile("${path.cwd}/modules/1_vpc_prepare/templates/cloud-init.yaml.tpl", {})
}

resource "ibm_is_floating_ip" "supp_vm_fip" {
  count          = var.vpc_supp_public_ip ? 1 : 0
  resource_group = var.resource_group
  name           = "${var.vpc_name}-supp-floating-ip"
  target         = ibm_is_instance.supp_vm_vsi[0].primary_network_interface[0].id
}

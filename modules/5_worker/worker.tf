################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Modeled off the OpenShift Installer work for IPI PowerVS
# https://github.com/openshift/installer/blob/master/data/data/powervs/bootstrap/vm/main.tf#L41
# https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/master/vm/main.tf
resource "ibm_pi_instance" "worker" {
  count = var.worker["count"]

  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_instance_name     = "${var.name_prefix}-worker-${count.index}"

  pi_sys_type   = var.system_type
  pi_proc_type  = var.processor_type
  pi_memory     = var.worker["memory"]
  pi_processors = var.worker["processors"]
  pi_image_id   = var.rhcos_image_id

  pi_network {
    network_id = var.powervs_dhcp_network_id
  }

  pi_key_pair_name = var.key_name
  pi_health_status = "WARNING"

  # docs/development.md describes the worker.ign file
  pi_user_data = base64encode(
    templatefile(
      "${path.cwd}/modules/5_worker/templates/worker.ign",
      {
        ignition_ip : var.ignition_ip,
        name : base64encode("${var.name_prefix}-worker-${count.index}"),
  }))
}

# The PowerVS instance may take a few minutes to start (per the IPI work)
resource "time_sleep" "wait_3_minutes" {
  depends_on      = [ibm_pi_instance.worker]
  create_duration = "3m"
}

data "ibm_pi_instance_ip" "worker" {
  count      = 1
  depends_on = [time_sleep.wait_3_minutes]

  pi_instance_name     = ibm_pi_instance.worker[count.index].pi_instance_name
  pi_network_name      = var.powervs_dhcp_network_name
  pi_cloud_instance_id = var.powervs_service_instance_id
}


# Creates a Support Machine for the VPC and PowerVS integration
# Ref: https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/dns/dns.tf
data "ibm_is_image" "supp_vm_image" {
  count = 1
  name  = var.supp_vm_image_name
}

data "ibm_is_instances" "vsis" {
  vpc_name = var.vpc_name
}

locals {
  vsis = [for x in data.ibm_is_instances.vsis.instances : x if x.name == "${var.vpc_name}-supp-vsi"]
}

resource "ibm_is_instance" "supp_vm_vsi" {
  # Create if it doesn't exist
  count = local.vsis == [] ? 1 : 0

  name    = "${var.vpc_name}-supp-vsi"
  vpc     = data.ibm_is_vpc.vpc.id
  zone    = data.ibm_is_vpc.vpc.subnets[0].zone
  keys    = [local.key_id]
  image   = data.ibm_is_image.supp_vm_image[0].id
  profile = "cx2d-8x16"
  # Profiles: https://cloud.ibm.com/docs/vpc?topic=vpc-profiles&interface=ui
  # Originally used cx2-2x4, however 8x16 includes 300G storage.

  resource_group = data.ibm_is_vpc.vpc.resource_group

  primary_network_interface {
    subnet          = data.ibm_is_vpc.vpc.subnets[0].id
    security_groups = [local.sg_id, local.cp_internal_sg[0].id]
  }

  user_data = templatefile("${path.cwd}/modules/1_vpc_prepare/templates/cloud-init.yaml.tpl", {})
}

resource "ibm_is_floating_ip" "supp_vm_fip" {
  resource_group = data.ibm_is_vpc.vpc.resource_group
  count          = local.vsis == [] ? 1 : 0
  name           = "${var.vpc_name}-supp-floating-ip"
  target         = ibm_is_instance.supp_vm_vsi[0].primary_network_interface[0].id
}


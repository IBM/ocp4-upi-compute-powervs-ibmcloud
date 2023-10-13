################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Creates an Intel VSI for the VPC and PowerVS workers 
# Ref: https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/dns/dns.tf

data "ibm_is_vpc" "vpc" {
  name = var.vpc_name
}

resource "ibm_is_instance" "workers_1" {
  count   = var.worker_1["count"]
  name    = "${var.name_prefix}-worker-${count.index}"
  vpc     = data.ibm_is_vpc.vpc.id
  zone    = var.worker_1["zone"]
  keys    = [var.vpc_key_id] #["r038-51cdecb0-c33b-4f80-814d-405c50c9a22b"]
  image   = var.rhcos_image_id
  profile = var.worker_1["profile"] #
  # Profiles: https://cloud.ibm.com/docs/vpc?topic=vpc-profiles&interface=ui
  # "cx2d-8x16" - 8x16 includes 300G storage.
  resource_group = data.ibm_is_vpc.vpc.resource_group

  primary_network_interface {
    subnet          = data.ibm_is_vpc.vpc.subnets[0].id
    security_groups = [var.target_worker_sg_id]
  }

  user_data = templatefile(
    "${path.cwd}/modules/6_worker/templates/worker.ign",
    {
      ignition_ip : var.ignition_ip,
      name : base64encode("${var.name_prefix}-worker-${count.index}"),
  })
}

# Waiting for Intel instance for a few minutes to start (per the IPI work)
resource "time_sleep" "wait_few_minutes" {
  depends_on      = [ibm_is_instance.workers_1]
  create_duration = "1m"
}

data "ibm_is_instance" "worker" {
  count      = 1
  depends_on = [time_sleep.wait_few_minutes]

  name = ibm_is_instance.workers_1[count.index].name
}

/*
resource "ibm_is_instance" "workers_2" {
  count   = var.worker_2["count"]
  name    = "${var.name_prefix}-worker-${count.index}"
  vpc     = data.ibm_is_vpc.vpc.id
  zone    = var.worker_2["zone"]
  keys    = [var.vpc_key_id]
  image   = var.rhcos_image_id
  profile = var.worker_2["profile"] #
  # Profiles: https://cloud.ibm.com/docs/vpc?topic=vpc-profiles&interface=ui
  # "cx2d-8x16" - 8x16 includes 300G storage.
  resource_group = data.ibm_is_vpc.vpc.resource_group

  primary_network_interface {
    subnet          = data.ibm_is_vpc.vpc.subnets[1].id
    security_groups = [var.target_worker_sg_id]
  }

  user_data = templatefile(
      "${path.cwd}/modules/6_worker/templates/worker.ign",
      {
        ignition_ip : var.ignition_ip,
        name : base64encode("${var.name_prefix}-worker-2-${count.index}"),
  })
}

resource "ibm_is_instance" "workers_3" {
  count   = var.worker_3["count"]
  name    = "${var.name_prefix}-worker-${count.index}"
  vpc     = data.ibm_is_vpc.vpc.id
  zone    = var.worker_3["zone"]
  keys    = [var.vpc_key_id]
  image   = var.rhcos_image_id
  profile = var.worker_3["profile"] #
  # Profiles: https://cloud.ibm.com/docs/vpc?topic=vpc-profiles&interface=ui
  # "cx2d-8x16" - 8x16 includes 300G storage.
  resource_group = data.ibm_is_vpc.vpc.resource_group

  primary_network_interface {
    subnet          = data.ibm_is_vpc.vpc.subnets[2].id
    security_groups = [var.target_worker_sg_id]
  }

  user_data = base64encode(
    templatefile(
      "${path.cwd}/modules/6_worker/templates/worker.ign",
      {
        ignition_ip : var.ignition_ip,
        name : base64encode("${var.name_prefix}-worker-3-${count.index}"),
  }))
}

*/

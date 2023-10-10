################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Creates an Intel VSI for the VPC and PowerVS workers 
# Ref: https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/dns/dns.tf

data "ibm_is_image" "rhcos_image" {
  count = 1
  name  = var.rhcos_image_name
}

data "ibm_is_vpc" "vpc" {
  name = var.vpc_name
}

resource "ibm_is_instance" "workers_1" {
  count   = var.worker_1["count"]
  name    = "${var.name_prefix}-worker-${count.index}" #"ca-worker-test-1"
  vpc     = data.ibm_is_vpc.vpc.id
  zone    = var.worker_1["zone"] #"ca-tor-2"
  keys    = [var.vpc_key_id]
  image   = var.rhcos_image_id #data.ibm_is_image.rhcos_image[0].id #var.rhcos_image_id
  profile = var.worker_1["profile"]             #
  # Profiles: https://cloud.ibm.com/docs/vpc?topic=vpc-profiles&interface=ui
  # "cx2d-8x16" - 8x16 includes 300G storage.
  resource_group = data.ibm_is_vpc.vpc.resource_group

  primary_network_interface {
    subnet          = "02r7-62686abe-3160-4be5-867f-9ceb914f4cac" #data.ibm_is_vpc.vpc.subnets[0].id
    security_groups = [var.target_worker_sg_id]
  }

  user_data = templatefile(
    "${path.cwd}/modules/6_worker/templates/worker.ign",
    {
      ignition_ip : var.ignition_ip,
      name : base64encode("${var.name_prefix}-worker-${count.index}"),
  })
}

# The PowerVS instance may take a few minutes to start (per the IPI work)
resource "time_sleep" "wait_3_minutes" {
  depends_on      = [ibm_is_instance.workers_1]
  create_duration = "3m"
}

data "ibm_is_instance" "worker" {
  count      = 1
  depends_on = [time_sleep.wait_3_minutes]

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

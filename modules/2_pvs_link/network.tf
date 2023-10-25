################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

resource "ibm_pi_cloud_connection" "new_cloud_connection" {
  pi_cloud_instance_id                = var.powervs_service_instance_id
  pi_cloud_connection_name            = "mac-cloud-conn-${var.cluster_id}"
  pi_cloud_connection_speed           = 1000
  pi_cloud_connection_global_routing  = true
  pi_cloud_connection_transit_enabled = true
  # Dev Note: Preference for Transit Gateway.
}

data "ibm_pi_network" "target_net" {
  pi_network_name      = var.powervs_network_name
  pi_cloud_instance_id = var.powervs_service_instance_id
}

resource "ibm_pi_cloud_connection_network_attach" "attach_cloud_connection_to_target_net" {
  pi_cloud_instance_id   = var.powervs_service_instance_id
  pi_cloud_connection_id = ibm_pi_cloud_connection.new_cloud_connection.cloud_connection_id
  pi_network_id          = data.ibm_pi_network.target_net.id
}

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

### IBM Cloud
ibmcloud_api_key = "<key>"

# VPC
vpc_name   = "<zone>"
vpc_region = "<region>"
vpc_zone   = "<zone>"

# PowerVS
powervs_service_instance_id = "<cloud_instance_ID>"
powervs_region              = "<region>"
powervs_zone                = "<zone>"

# Required for ignition and automation to run.
powervs_bastion_ip         = ""
powervs_bastion_private_ip = ""

# The PowerVS machine cidr for your network
# powervs_machine_cidr = "192.168.200.0/24"

# Zone 1's Worker Details
worker_1 = { count = 1, profile = "cx2d-8x16", zone = "ca-tor-1" }

# Zone 2's Worker Details
# worker_2                = { count = 1, profile = "cx2d-8x16", zone = "ca-tor-2" }

# Zone 3's Worker Details
# worker_3                = { count = 1, profile = "cx2d-8x16", zone = "ca-tor-3" }

# Public and Private Key for Bastion Nodes
public_key_file  = "data/compute_id_rsa.pub"
private_key_file = "data/compute_id_rsa"

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

# VPC Workers
# Zone 1
worker_1 = { count = "1", profile = "cx2-8x16", "zone" = "au-syd-1" }
# Zone 2
worker_2 = { count = "0", profile = "cx2-8x16", "zone" = "au-syd-2" }
# Zone 3
worker_3 = { count = "0", profile = "cx2-8x16", "zone" = "au-syd-3" }

# Public and Private Key for Bastion Nodes
public_key_file  = "data/id_rsa.pub"
private_key_file = "data/id_rsa"
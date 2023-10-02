################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_is_subnets" "vpc_subnets" {
  routing_table_name = data.ibm_is_vpc.vpc.default_routing_table_name
}
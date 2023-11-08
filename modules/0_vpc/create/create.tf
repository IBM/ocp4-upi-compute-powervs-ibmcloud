################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Dev Note: the dns.enable_hub = false by default, we may consider in the future setting it so we don't 
# have to set a machineconfig with resolv.conf.d settings
# Ref https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_vpc
resource "ibm_is_vpc" "vpc" {
  name           = var.vpc_name
  resource_group = var.vpc_resource_group
}

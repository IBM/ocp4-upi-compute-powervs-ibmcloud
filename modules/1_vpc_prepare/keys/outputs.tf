################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "vpc_check_key" {
  value = var.vpc_create || var.create_custom_subnet ? module.create_new[0].vpc_check_key : module.check.check_key
}

output "vpc_key_id" {
  value = var.vpc_create || var.create_custom_subnet ? module.create_new[0].vpc_key_id : module.check.keys
}

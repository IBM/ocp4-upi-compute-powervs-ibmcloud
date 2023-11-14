################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "keys" {
  value = length(local.keys) == 0 ? null : local.keys[0]
}

output "check_key" {
  value = local.check_key
}

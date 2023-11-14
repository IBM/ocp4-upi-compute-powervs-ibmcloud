################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_is_ssh_keys" "keys" {
  # Region is implicit
}

# Manages the ssh keys
locals {
  public_key_file = var.public_key_file == "" ? "${path.cwd}/data/id_rsa.pub" : "${path.cwd}/${var.public_key_file}"
  public_key      = var.public_key == "" ? file(coalesce(local.public_key_file, "/dev/null")) : var.public_key
}

locals {
  # Avoid duplication, irrespective of the public key's name
  current_key = trimspace(file(local.public_key_file))
  key_comps   = split(" ", local.current_key)
  check_key   = "${local.key_comps[0]} ${local.key_comps[1]}"
  keys        = [for x in data.ibm_is_ssh_keys.keys.keys : x.id if x.public_key == local.check_key]
}

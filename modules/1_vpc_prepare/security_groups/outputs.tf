################################################################
# Copyright 2025 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "target_worker_sg_id" {
  value = ibm_is_security_group.worker_vm_sg[0].id
}

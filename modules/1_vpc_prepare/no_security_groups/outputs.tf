################################################################
# Copyright 2025 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "target_worker_sg_id" {
  value = data.ibm_security_group.workers_sg.id
}
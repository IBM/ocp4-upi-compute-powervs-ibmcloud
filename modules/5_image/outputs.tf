################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "rhcos_image_id" {
  value = ibm_is_image.worker_image_id.id
}

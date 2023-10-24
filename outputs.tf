################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "instructions" {
  value = <<EOF
Login to you OCP cluster and get oc get nodes to see your Intel nodes.

oc get nodes -l kubernetes.io/arch=amd64
EOF
}
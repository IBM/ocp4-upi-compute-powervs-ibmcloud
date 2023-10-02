################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "vpc_check_key" {
  description = "The VPC SSH Key that was added/checked against existing keys"
  value       = module.vpc_support.vpc_check_key
}

output "instructions" {
  value = <<EOF
Login to you OCP cluster and get oc get nodes to see your Intel nodes.

oc get nodes -l kubernetes.io/arch=amd64

The support machine node in VPC can be destroyed at this point.
EOF
}
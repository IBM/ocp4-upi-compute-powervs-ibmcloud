#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Variables:
export PVS_GATEWAY=${gateway}

# The template (bash array) is going to be filled with the ipv4 cidrs
# entries[1]=10.248.0.0/24
declare -a entries
%{ for index, cidr in cidrs_ipv4 ~}
entries[${format("%d", index + 1)}]="${cidr}"
%{ endfor ~}
export PVS_GATEWAY
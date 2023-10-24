#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# sets up the interface routes

cat << EOF | nmcli connection edit 'System env3'
goto ipv4
%{ for cidr in cidrs_ipv4 ~}
set routes ${cidr} ${gateway}
%{ endfor ~}
save
quit
EOF

nmcli device up env3

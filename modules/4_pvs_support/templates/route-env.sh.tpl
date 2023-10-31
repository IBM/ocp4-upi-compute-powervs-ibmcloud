#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# sets up the interface routes
INT_IFACE=""
nmcli -f Name -t connection | grep -v lo | while read IFACE
do
FOUND="$(nmcli -t -f ipv4.addresses connection show "$${IFACE}" | grep ${bastion_ip})"
if [ -n "$${FOUND}" ]
then
INT_IFACE="$${IFACE}"
fi
done

cat << EOF | nmcli connection edit "$${INT_IFACE}"
goto ipv4
%{ for cidr in cidrs_ipv4 ~}
set routes ${cidr} ${gateway}
%{ endfor ~}
save
quit
EOF

nmcli device up env3

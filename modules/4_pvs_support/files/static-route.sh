#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# This script updates the dhcpd config.

# Desired results:
# option rfc3442-classless-static-routes code 121 = array of integer 8;
# option rfc3442-classless-static-routes 24, 10, 248, 0, 192, 168, 200, 1;

# We shouldn't need the following, copying here for future dev, if needed.
# option ms-classless-static-routes code 249 = array of integer 8;
# option ms-classless-static-routes 24, 10, 248, 0, 192, 168, 200, 1;

if [ ! -f /etc/dhcp/classless-static-routes.conf ]
then
cat << EOF > /etc/dhcp/classless-static-routes.conf
option rfc3442-classless-static-routes code 121 = array of integer 8;
EOF

source route.env

# Gateway formated
GATEWAY_FORMAT="$(echo ${PVS_GATEWAY} | sed 's|\.|,|g')"
echo "GATEWAY_FORMAT: ${GATEWAY_FORMAT}"

# CONDITIONAL_COMMA [,]
# SUBNET_MASK /24 
# SUBNET 10, 248, 0, 
# 192, 168, 200, 1 GATEWAY_FORMAT
echo -n "option rfc3442-classless-static-routes" >> /etc/dhcp/classless-static-routes.conf
PRIOR=""
for i in "${!entries[@]}"; do
    echo "Creating static-route entry: ${entries[$i]}"
    if [ -n "${PRIOR}" ]
    then 
        echo -n "," >> /etc/dhcp/classless-static-routes.conf
    else
        PRIOR="IN-USE"
    fi

    SUBNET_MASK=$(echo ${entries[$i]} | sed 's|/| |g' | awk '{print $NF}')

    # Dev Test: 
    #SUBNET=$(echo "192.168.200.0/24" | sed 's|/| |g' | awk '{print $1}' | sed 's|\.| |g')
    SUBNET=($(echo ${entries[$i]} | sed 's|/| |g' | awk '{print $1}' | sed 's|\.| |g'))

    # DHCPD requires a mask in a special form. We're relying on subnet masks and greatest bits determining how many numbers we include.
    SUBNET_STR=""
    if [ ${SUBNET_MASK} -gt 25 ]
    then
        echo "subnet needs four places"
        SUBNET_STR="${SUBNET[0]},${SUBNET[1]},${SUBNET[2]},${SUBNET[3]}"
    elif [ ${SUBNET_MASK} -gt 16 ]
    then
        echo "subnet needs tree places"
        SUBNET_STR="${SUBNET[0]},${SUBNET[1]},${SUBNET[2]}"
    elif [ ${SUBNET_MASK} -gt 8 ]
    then
        echo "subnet needs two places"
        SUBNET_STR="${SUBNET[0]},${SUBNET[1]}"
    else
        echo "subnet needs one place"
        SUBNET_STR="${SUBNET[0]}"
    fi
    echo ${SUBNET_STR}

    echo -n " ${SUBNET_MASK}, ${SUBNET_STR}, ${GATEWAY_FORMAT}" >> /etc/dhcp/classless-static-routes.conf
done

# Update the static routes for the power nodes.
for NODE_IP in $(oc get nodes -l kubernetes.io/arch=ppc64le -owide --no-headers=true| awk '{print $6}')
do
    echo "NODE_IP to use for classless static route: ${NODE_IP}"
    echo -n "," >> /etc/dhcp/classless-static-routes.conf

    # Dev Test: 
    SUBNET=($(echo ${NODE_IP} | sed 's|/| |g' | awk '{print $1}' | sed 's|\.| |g'))

    # DHCPD requires a mask in a special form. We're relying on subnet masks and greatest bits determining how many numbers we include.
    # Always 32-bit mask
    SUBNET_STR="${SUBNET[0]},${SUBNET[1]},${SUBNET[2]},${SUBNET[3]}"
    echo ${SUBNET_STR}

    echo -n " 32, ${SUBNET_STR}, ${GATEWAY_FORMAT}" >> /etc/dhcp/classless-static-routes.conf
done

# Finally close the static routes
echo ";" >> /etc/dhcp/classless-static-routes.conf

echo "Static routes are:"
cat /etc/dhcp/classless-static-routes.conf
echo ""

echo "Updating the dhcpd.conf include"
cat << EOF >> /etc/dhcp/dhcpd.conf
include "/etc/dhcp/classless-static-routes.conf";
EOF

echo "Restarting the dhcpd"
systemctl restart dhcpd

# Need to login to each Power Node
for NODE_IP in $(oc get nodes -l kubernetes.io/arch=ppc64le -owide --no-headers=true| awk '{print $6}')
do
echo "Restarting NetworkManager at NODE_IP: ${NODE_IP}"
# Dev Note: tried out the following approaches
# 1. systemctl restart NetworkManager - had to reboot the nodes.
# 2. br-ex up to refresh the dhcp lease - refreshed the single device
ssh core@${NODE_IP} sudo nmcli device up br-ex
done

else
    echo "Skipping the static route assignement, file exists"
fi
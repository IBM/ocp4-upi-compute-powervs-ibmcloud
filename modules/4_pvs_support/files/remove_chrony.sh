#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# The script removes chrony.

if [ -f /etc/chrony.conf.backup ]
then
    echo "backing up chronyd"
    mv -f /etc/chrony.conf.backup /etc/chrony.conf || true
fi

echo "Restart chronyd"
sleep 10
systemctl restart chronyd
echo "Done with the chronyd"
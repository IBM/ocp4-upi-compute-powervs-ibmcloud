#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# The script creates the butane configuration and then uses the configuration to populate the workers with the right resolv.conf file.

VAL=$(oc get mc -o yaml | grep -c 99-worker-dnsconfig)
if [ ${VAL} -eq 0 ]
then 

dnf install -y butane

cat << EOF > butane-resolv-conf.bu
variant: openshift
version: 4.12.0
metadata:
name: 99-worker-dnsconfig
labels:
    machineconfiguration.openshift.io/role: worker
storage:
files:
    - path: /etc/resolv.conf
    mode: 0644
    overwrite: true
    contents:
        inline: |
        search $(hostname --long)
        nameserver $(hostname -i | awk '{print $NF}')
EOF

butane butane-resolv-conf.bu > 99-worker-dnsconfig.yaml
cat 99-worker-dnsconfig.yaml

oc apply -f 99-worker-dnsconfig.yaml
echo "Done creating the dnsconfig for the workers"

else 

echo "Skipping the butane changes"

fi
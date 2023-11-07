#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# The script adds chrony.

echo "Generate the configuration:"
cat << EOF > vars.yaml
---
subnets:
EOF
for SUBNET in $(ip r | grep via | grep -v default | awk '{print $1}')
do 
cat << EOF >> vars.yaml
  - { subnet: '${SUBNET}'}
EOF
done

# Backup the chronyd configuration
echo "Backing up prior configs"
mv /etc/chrony.conf.backup /etc/chrony.conf.backup-$(date +%s) || true
cp -f /etc/chrony.conf /etc/chrony.conf.backup

echo "Make the inventory file"
cat << EOF > inventory
[vmhost]
localhost ansible_connection=local ansible_user=root
EOF

echo "Creating the chrony chrony.yaml"
cat << EOF > chrony.yaml
---
- name: chrony
  hosts: all
  tasks:
  - name: update chrony config
    ansible.builtin.replace:
      path: /etc/chrony.conf
      regexp: "# Allow NTP client access from local network.\n"
      replace: "# Allow NTP client access from local network.\nallow {{item.subnet}}\n"
    loop: "{{ subnets }}"
EOF

echo "Running the chronyd changes"
ansible-playbook chrony.yaml --extra-vars=@vars.yaml -i inventory

echo "Restart chronyd"
sleep 10
systemctl restart chronyd
echo "Done with the chronyd"

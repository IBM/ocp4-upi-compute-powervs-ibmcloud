################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# The script updates the haproxy entries for the new Intel nodes. 

## Example
# backend ingress-http
#     balance source
#     server ZYZ-worker-0-http-router0 192.168.200.254:80 check
#     server ZYZ-worker-1-http-router1 192.168.200.79:80 check
#     server ZYZ-x86-worker-0-http-router2 10.245.0.45:80 check

# backend ingress-https
#     balance source
#     server ZYZ-worker-0-https-router0 192.168.200.254:443 check
#     server ZYZ-worker-1-https-router1 192.168.200.79:443 check
#     server ZYZ-x86-worker-0-http-router2 10.245.0.45:443 check

# Alternatives:
# 1. Replicate ocp4-helper-node templates/haproxy.cfg.j2 and restart haproxy
# - replaces the existing haproxy.cfg with a new and potentially invalid cfg (as it may have changed since install).
# 2. sed / grep replacement which is a pain (see git history for this file)

## Create the vars file
echo "Generate the configuration:"
cat << EOF > vars.yaml
---
workers:
EOF
for INTEL_WORKER in $(oc get nodes -lkubernetes.io/arch=amd64 --no-headers=true -ojson | jq  -c '.items[].status.addresses')
do 
  T_IP=$(echo "${INTEL_WORKER}" | jq -r '.[] | select(.type == "InternalIP").address')
  T_HOSTNAME=$(echo "${INTEL_WORKER}" | jq -r '.[] | select(.type == "Hostname").address')
  echo "FOUND: ${T_IP} ${T_HOSTNAME}"
cat << EOF >> vars.yaml
  - { hostname: '${T_HOSTNAME}', ip: '${T_IP}' }
EOF
done

# Backup the haproxy configuration
echo "Backing up prior configs"
mv /etc/haproxy/haproxy.cfg.backup /etc/haproxy/haproxy.cfg.backup-$(date +%s) || true
cp -f /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup

echo "Make the inventory file"
cat << EOF > inventory
[vmhost]
localhost ansible_connection=local ansible_user=root
EOF

echo "Creating the loadbalancer lb.yaml"
cat << EOF > lb.yaml
---
- name: Create the Load Balancer Entries - http/https
  hosts: all
  tasks:
  - name: create the http entries
    ansible.builtin.replace:
      path: /etc/haproxy/haproxy.cfg
      regexp: ".*backend ingress-http\n.*balance source\n"
      replace: "backend ingress-http\n    balance source\n    server {{ item.hostname }}-http-router0 {{ item.ip }}:80 check\n"
    loop: "{{ workers }}"
  - name: create the https entries
    ansible.builtin.replace:
      path: /etc/haproxy/haproxy.cfg
      regexp: ".*backend ingress-https\n.*balance source\n"
      replace: "backend ingress-https\n    balance source\n    server {{ item.hostname }}-https-router0 {{ item.ip }}:443 check\n"
    loop: "{{ workers }}"
EOF

echo "Running the haproxy changes"
ansible-playbook lb.yaml --extra-vars=@vars.yaml -i inventory

echo "Restart haproxy"
sleep 10
systemctl restart haproxy
echo "Done with the haproxy"
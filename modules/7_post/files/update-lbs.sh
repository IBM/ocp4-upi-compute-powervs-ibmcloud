################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# The script updates the haproxy entries for the new intel nodes. 

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

for INTEL_WORKER in $(oc get nodes -lkubernetes.io/arch=amd64 --no-headers=true -ojson | jq  -c '.items[].status.addresses')
do 
  T_IP=$(echo "${INTEL_WORKER}" | jq -r '.[] | select(.type == "InternalIP").address')
  T_HOSTNAME=$(echo "${INTEL_WORKER}" | jq -r '.[] | select(.type == "Hostname").address')
  echo "FOUND: ${T_IP} ${T_HOSTNAME}"

  if grep ${T_HOSTNAME}-http-router0 /etc/haproxy/haproxy.cfg
  then
    continue
  fi
  HTTP_LN=$(grep -Rn -A3 'backend ingress-http$' /etc/haproxy/haproxy.cfg | grep 'server ' | head -n 1 | sed 's|-| |' | awk '{print $1}')
  sed -i.bak "${HTTP_LN}i\
    server ${T_HOSTNAME}-http-router0 ${T_IP}:80 check
" /etc/haproxy/haproxy.cfg
  HTTPS_LN=$(grep -Rn -A3 'backend ingress-https$' /etc/haproxy/haproxy.cfg | grep 'server ' | head -n 1 | sed 's|-| |' | awk '{print $1}')
  sed -i.bak "${HTTPS_LN}i\
    server ${T_HOSTNAME}-https-router0 ${T_IP}:443 check
" /etc/haproxy/haproxy.cfg
done

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# The script updates the haproxy entries for the new intel nodes. 

if [ -f /etc/haproxy/haproxy.cfg.backup ]
then
    echo "restoring haproxy"
    mv -f /etc/haproxy/haproxy.cfg.backup /etc/haproxy/haproxy.cfg || true
fi

echo "Restart haproxy"
sleep 10
systemctl restart haproxy
echo "Done with the haproxy"
#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# The script creates a second MachineConfigPool `power` where preinstall-worker-kargs is moved.

VAL=$(oc get mc -o yaml | grep -c preinstall-worker-kargs)
if [ ${VAL} -eq 1 ]
then 
echo "Migrating the preinstall-worker-kargs"

# Assign a role label in addition to worker called power [To existing running PowerVs worker nodes ]
echo "list of worker nodes: "
oc get nodes -l kubernetes.io/arch=ppc64le,node-role.kubernetes.io/worker --no-headers=true

for POWER_NODE in $(oc get nodes -l kubernetes.io/arch=ppc64le,node-role.kubernetes.io/worker --no-headers=true | awk '{print $1}')
do
echo "Adding power label to Power Node: ${POWER_NODE}"
oc label node ${POWER_NODE} node-role.kubernetes.io/power=

echo "Removing worker label to Power Node: ${POWER_NODE}"
oc label node ${POWER_NODE} node-role.kubernetes.io/worker-
done
echo "Done Labeling the nodes"

# Check the Nodes and you should see two roles listed
echo "The following nodes have the power node-role label"
oc get nodes -l kubernetes.io/arch=ppc64le,node-role.kubernetes.io/power --no-headers=true

# Create a mcp for power
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
    name: power
spec:
    machineConfigSelector:
        matchExpressions:
        - key: machineconfiguration.openshift.io/role
          operator: In
          values: [worker,power]
    nodeSelector:
        matchLabels:
            node-role.kubernetes.io/power: ""
EOF
echo "Done creating the 'power' MCP"

# Check to see the MachineConfigPools
echo "Verify the MCPs are listed:"
oc get mcp

# Create the 'preinstall-power-kargs' mc and check it is part of the power mcp
echo "Create the preinstall power kargs mc"
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: power
  name: preinstall-power-kargs
spec:
  kernelArguments:
  - rd.multipath=default
  - root=/dev/disk/by-label/dm-mpath-root
EOF
echo "Done creating mc"

# Wait on the power mcp to update
echo "waiting small period of time for reconciliation in mcps"
sleep 60
MCP_IDX=0
MCP_COUNT=50
MACHINE_COUNT=$(oc get mcp power -o json | jq -r '.status.machineCount')
while [ $(oc get mcp power -o json | jq -r '.status.readyMachineCount') -ne ${MACHINE_COUNT} ]
do
    echo "WAITING: some more"
    oc get mcp power -o json | jq -r '.status.readyMachineCount'

    MCP_IDX=$(($MCP_IDX + 1))
    if [ "${MCP_IDX}" -gt "${MCP_COUNT}" ]
    then
        echo "failed to wait on the machine count"
        exit 1
    fi
    sleep 30
done

# Delete the mc 'preinstall-worker-kargs'
echo "Deleting the worker kargs"
oc delete mc preinstall-worker-kargs

# Wait on the worker mcp to update
echo "waiting small period of time for reconciliation in mcps"
sleep 60
MCP_IDX=0
MCP_COUNT=50
MACHINE_COUNT=$(oc get mcp power -o json | jq -r '.status.machineCount')
while [ $(oc get mcp power -o json | jq -r '.status.readyMachineCount') -ne ${MACHINE_COUNT} ]
do
    echo "WAITING: some more"
    oc get mcp power -o json | jq -r '.status.readyMachineCount'

    MCP_IDX=$(($MCP_IDX + 1))
    if [ "${MCP_IDX}" -gt "${MCP_COUNT}" ]
    then
        echo "failed to wait on the machine count"
        exit 1
    fi
    sleep 30
done

# You can check the power nodes.
echo "Now checking the openshift-machine-config operator status"
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-daemon -l kubernetes.io/arch=ppc64le

# Now you can manually download the worker ignition file and use it to create the intel worker nodes. They should be listed under worker MCP.
echo "Completed setup of the power mcp"

else 

echo "Skipping mcp creation as the preinstall-worker-kargs does not exist"
oc get mc | grep -v rendered- | grep worker

fi

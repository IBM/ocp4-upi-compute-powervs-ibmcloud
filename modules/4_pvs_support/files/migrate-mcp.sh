#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# The script creates a second MachineConfigPool `power` where preinstall-worker-kargs is moved.

# Function to wait for MCP to stabilize
wait_for_mcp_stable() {
    local MCP_NAME=$1
    local MAX_RETRIES=${2:-50}
    local RETRY_DELAY=${3:-30}
    
    echo "========================================"
    echo "Waiting for ${MCP_NAME} MCP to stabilize..."
    echo "========================================"
    sleep 60
    
    local RETRY_COUNT=0
    
    while [ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]; do
        local MACHINE_COUNT=$(oc get mcp ${MCP_NAME} -o json | jq -r '.status.machineCount // 0')
        local READY_COUNT=$(oc get mcp ${MCP_NAME} -o json | jq -r '.status.readyMachineCount // 0')
        local UPDATED=$(oc get mcp ${MCP_NAME} -o json | jq -r '.status.conditions[] | select(.type=="Updated") | .status // "Unknown"')
        local UPDATING=$(oc get mcp ${MCP_NAME} -o json | jq -r '.status.conditions[] | select(.type=="Updating") | .status // "Unknown"')
        local DEGRADED=$(oc get mcp ${MCP_NAME} -o json | jq -r '.status.conditions[] | select(.type=="Degraded") | .status // "Unknown"')
        
        echo "[Attempt ${RETRY_COUNT}/${MAX_RETRIES}] ${MCP_NAME} MCP Status:"
        echo "  Machines: ${READY_COUNT}/${MACHINE_COUNT}"
        echo "  Updated: ${UPDATED}, Updating: ${UPDATING}, Degraded: ${DEGRADED}"
        
        if [ "${DEGRADED}" == "True" ]; then
            echo "ERROR: ${MCP_NAME} MCP is degraded!"
            oc get mcp ${MCP_NAME} -o yaml
            exit 1
        fi
        
        if [ "${READY_COUNT}" -eq "${MACHINE_COUNT}" ] && [ "${UPDATED}" == "True" ] && [ "${UPDATING}" == "False" ]; then
            echo "SUCCESS: ${MCP_NAME} MCP is stable and ready"
            echo "========================================"
            return 0
        fi
        
        RETRY_COUNT=$((RETRY_COUNT + 1))
        sleep ${RETRY_DELAY}
    done
    
    echo "ERROR: Timeout waiting for ${MCP_NAME} MCP to stabilize"
    oc get mcp ${MCP_NAME} -o yaml
    exit 1
}

VAL=$(oc get mc -o yaml | grep -c preinstall-worker-kargs)
if [ ${VAL} -eq 1 ]
then 
    echo "Migrating the preinstall-worker-kargs"

    # Assign a role label in addition to worker called power [To existing running PowerVs worker nodes ]
    echo "list of worker nodes: "
    oc get nodes -l kubernetes.io/arch=ppc64le,node-role.kubernetes.io/worker --no-headers=true

    for POWER_NODE in $(oc get nodes -l kubernetes.io/arch=ppc64le,node-role.kubernetes.io/worker --no-headers=true | awk '{print $1}')
    do
        echo "Adding label to Power Node: ${POWER_NODE}"
        oc label node ${POWER_NODE} node-role.kubernetes.io/power=
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

    # Check if PowerVS nodes already have multipath kernel arguments
    # PowerVS nodes typically don't need multipath, but if they were deployed with it
    # in a previous run, we should not try to apply it again
    echo "========================================"
    echo "Checking PowerVS node configuration..."
    echo "========================================"

    NEEDS_KARGS=false
    HAS_ANY_MULTIPATH=false

    for POWER_NODE in $(oc get nodes -l kubernetes.io/arch=ppc64le,node-role.kubernetes.io/power --no-headers=true | awk '{print $1}')
    do
        echo "Checking kernel args on node: ${POWER_NODE}"
        # Check if node already has rd.multipath=default in kernel args
        HAS_MULTIPATH=$(oc debug node/${POWER_NODE} -- chroot /host cat /proc/cmdline 2>/dev/null | grep -c "rd.multipath=default" || echo "0")

        if [ "${HAS_MULTIPATH}" -eq 0 ]; then
            echo "  Node ${POWER_NODE} does NOT have multipath kernel args"
            NEEDS_KARGS=true
        else
            echo "  Node ${POWER_NODE} already has multipath kernel args"
            HAS_ANY_MULTIPATH=true
        fi
    done

    # Decision logic:
    # 1. If ANY node has multipath, skip MC creation (nodes already configured)
    # 2. If NO nodes have multipath, also skip (PowerVS doesn't need it)
    # 3. Only create MC if explicitly needed for mixed scenarios

    if [ "${HAS_ANY_MULTIPATH}" = true ]; then
        echo "========================================"
        echo "SKIPPING preinstall-power-kargs creation"
        echo "PowerVS nodes already have multipath kernel arguments from previous deployment"
        echo "No MachineConfig changes needed"
        echo "========================================"
    elif [ "${NEEDS_KARGS}" = true ]; then
        echo "========================================"
        echo "SKIPPING preinstall-power-kargs creation"
        echo "PowerVS nodes use native PowerVS storage and don't require multipath"
        echo "Multipath is only needed for VPC Intel workers"
        echo "========================================"
    fi

    # Wait briefly for power MCP to stabilize
    # Since we're not creating any new MachineConfigs, this should be quick
    echo "========================================"
    echo "Waiting for power MCP to stabilize..."
    echo "========================================"
    sleep 30

    # Quick check that power MCP is healthy
    POWER_MCP_STATUS=$(oc get mcp power -o json | jq -r '.status.conditions[] | select(.type=="Updated") | .status // "Unknown"')
    POWER_MCP_UPDATING=$(oc get mcp power -o json | jq -r '.status.conditions[] | select(.type=="Updating") | .status // "Unknown"')

    echo "Power MCP Status: Updated=${POWER_MCP_STATUS}, Updating=${POWER_MCP_UPDATING}"

    if [ "${POWER_MCP_STATUS}" != "True" ] || [ "${POWER_MCP_UPDATING}" != "False" ]; then
        echo "Power MCP needs time to stabilize, waiting..."
        wait_for_mcp_stable "power" 20 30
    else
        echo "Power MCP is stable and ready"
    fi

    # Delete the mc 'preinstall-worker-kargs'
    echo "Deleting the worker kargs"
    oc delete mc preinstall-worker-kargs

    # Wait on the worker mcp to update (FIXED: was incorrectly checking power MCP)
    wait_for_mcp_stable "worker" 50 30

    # Additional stabilization wait to ensure API endpoints are ready
    echo "========================================"
    echo "Additional stabilization wait for API endpoints..."
    echo "========================================"
    sleep 180
    echo "Worker MCP should now be stable and API endpoints ready"

    # You can check the power nodes.
    echo "========================================"
    echo "Checking the openshift-machine-config operator status"
    echo "========================================"
    oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-daemon -l kubernetes.io/arch=ppc64le

    # Verify MCS is responding
    echo "Verifying Machine Config Server availability..."
    MAX_MCS_RETRIES=10
    MCS_RETRY=0
    while [ ${MCS_RETRY} -lt ${MAX_MCS_RETRIES} ]; do
        if oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server --no-headers | grep -q Running; then
            echo "Machine Config Server pods are running"
            break
        fi
        echo "Waiting for MCS pods... (${MCS_RETRY}/${MAX_MCS_RETRIES})"
        MCS_RETRY=$((MCS_RETRY + 1))
        sleep 10
    done

    # Display final MCP status
    echo "========================================"
    echo "Final MCP Status:"
    echo "========================================"
    oc get mcp

    # Now you can manually download the worker ignition file and use it to create the intel worker nodes. They should be listed under worker MCP.
    echo "========================================"
    echo "Completed setup of the power mcp"
    echo "Worker MCP is ready for Intel/AMD64 worker nodes"
    echo "========================================"

else 
    echo "Skipping mcp creation as the preinstall-worker-kargs does not exist"
    oc get mc | grep -v rendered- | grep worker
fi

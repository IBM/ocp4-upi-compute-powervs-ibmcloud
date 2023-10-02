#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Var: ${self.triggers.count_1}
COUNT_1="${2}"

# Var: ${self.triggers.count_2}
COUNT_2="${3}"

# Var: ${self.triggers.count_3}
COUNT_3="${4}"

# Var: self.triggers.name_prefix
NAME_PREFIX="${1}"

IDX=0
while [ "$IDX" -lt "$COUNT" ]
do
    echo "Removing the taint for Worker: ${NAME_PREFIX}-worker-1-${IDX}"
    oc adm taint node ${NAME_PREFIX}-worker-${IDX} node.cloudprovider.kubernetes.io/uninitialized- \
        || true
    IDX=$(($IDX + 1))
done

IDX=0
while [ "$IDX" -lt "$COUNT" ]
do
    echo "Removing the taint for Worker: ${NAME_PREFIX}-worker-2-${IDX}"
    oc adm taint node ${NAME_PREFIX}-worker-${IDX} node.cloudprovider.kubernetes.io/uninitialized- \
        || true
    IDX=$(($IDX + 1))
done

IDX=0
while [ "$IDX" -lt "$COUNT" ]
do
    echo "Removing the taint for Worker: ${NAME_PREFIX}-worker-3-${IDX}"
    oc adm taint node ${NAME_PREFIX}-worker-${IDX} node.cloudprovider.kubernetes.io/uninitialized- \
        || true
    IDX=$(($IDX + 1))
done
#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Var: ${self.triggers.count_1}
COUNT_1="${1}"

# Var: ${self.triggers.count_2}
COUNT_2="${2}"

# Var: ${self.triggers.count_3}
COUNT_3="${3}"

# Var: self.triggers.name_prefix
NAME_PREFIX="${2}"

IDX=0
while [ "$IDX" -lt "$COUNT_1" ]
do
    echo "Removing the Worker Zone 1: ${NAME_PREFIX}-worker-1-${IDX}"
    oc delete node ${NAME_PREFIX}-worker-${IDX} || true
    IDX=$(($IDX + 1))
done

IDX=0
while [ "$IDX" -lt "$COUNT_2" ]
do
    echo "Removing the Worker Zone 2: ${NAME_PREFIX}-worker-2-${IDX}"
    oc delete node ${NAME_PREFIX}-worker-${IDX} || true
    IDX=$(($IDX + 1))
done

IDX=0
while [ "$IDX" -lt "$COUNT_3" ]
do
    echo "Removing the Worker Zone 3: ${NAME_PREFIX}-worker-3-${IDX}"
    oc delete node ${NAME_PREFIX}-worker-${IDX} || true
    IDX=$(($IDX + 1))
done

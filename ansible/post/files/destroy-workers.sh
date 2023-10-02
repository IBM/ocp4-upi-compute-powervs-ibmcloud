#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Var: ${self.triggers.count}
COUNT="${1}"

# Var: self.triggers.name_prefix
NAME_PREFIX="${2}"

IDX=0
while [ "$IDX" -lt "$COUNT" ]
do
    echo "Removing the Worker: ${NAME_PREFIX}-worker-${IDX}"
    oc delete node ${NAME_PREFIX}-worker-${IDX} || true
    IDX=$(($IDX + 1))
done
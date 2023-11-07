#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

ibmcloud plugin show cis

# Find the domain per the bastion.

# List instances

ibmcloud cis instances --output json


ibmcloud cis domains -i 7976ba7c-5530-4b75-a57d-0f75516f061b

ibmcloud cis dns-records  b9f3fe9febe35f43faf2aa09d498217b -i 7976ba7c-5530-4b75-a57d-0f75516f061b

# Get the API Server
oc config view --minify=true -ojson | jq -r '.clusters[].cluster.server'

# 
BASE_DOMAIN=$(oc get route console -n openshift-console -o json | jq -r '.status.ingress[].host' | sed 's|console-openshift-console.apps.||g')
echo ${BASE_DOMAIN} | awk '{
  n = split($0, t, ".")
  x = ""
  for (i = 0; ++i <= n;)
    if (i + 1 > n)
      printf t[i]
    else
      printf t[i]"."
  }'
################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# The script updates the front end listeners for Internal/External UPI automation generated Load Balancers
IBMCLOUD_API_KEY=$1
VPC_REGION=$2
RESOURCE_GROUP=$3
VPC_NAME=$4

echo "Login to the IBM Cloud"
ibmcloud login --apikey ${IBMCLOUD_API_KEY} -r ${VPC_REGION} -g ${RESOURCE_GROUP}

HTTP_POOL="ingress-http"
HTTPS_POOL="ingress-https"

# Find the Load Balancers
INTERNAL_LB_NAME=`ibmcloud is lbs | grep internal-loadbalancer | awk '{print $2}'`
EXTERNAL_LB_NAME=`ibmcloud is lbs | grep external-loadbalancer | awk '{print $2}'`

# Fetch IP addresses of newly added x86 workers
for IP in $(oc get nodes -l kubernetes.io/arch=amd64 -owide --no-headers=true | awk '{print $6}')
do

  # Modify front end listeners for internal load balancers with Pool name 'ingress-http' and 'ingress-https'
  ibmcloud is load-balancer-pool-member-create \
        "${INTERNAL_LB_NAME}" "${HTTP_POOL}" 80 ${IP} --vpc "${VPC_NAME}" --output JSON

  sleep 60

  ibmcloud is load-balancer-pool-member-create \
        "${INTERNAL_LB_NAME}" "${HTTPS_POOL}" 443 ${IP} --vpc "${VPC_NAME}" --output JSON

  # Modify front end listeners for external load balancers with Pool name 'ingress-http' and 'ingress-https'
  ibmcloud is load-balancer-pool-member-create \
        "${EXTERNAL_LB_NAME}" "${HTTP_POOL}" 80 ${IP} --vpc "${VPC_NAME}" --output JSON

  sleep 60

  ibmcloud is load-balancer-pool-member-create \
        "${EXTERNAL_LB_NAME}" "${HTTPS_POOL}" 443 ${IP} --vpc "${VPC_NAME}" --output JSON

done


################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# The script removes the entry added to the front end listeners for Internal/External Load Balancers
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

# Function to wait till Load Balancer state is active
function wait_for_active_lb_state() {
  for (( i=1 ; i<=20 ; i++ ));
  do
    LB_STATE=`ibmcloud is lbs | grep $1 | awk '{print $6}'`
    echo "Load Balancer - $1 is having state - $LB_STATE"
    if [[ $LB_STATE == "active" ]]
    then
     break
    else
      sleep 10
    fi
  done
}

# Fetch IP addresses of newly added x86 workers
for IP in $(oc get nodes -l kubernetes.io/arch=amd64 -owide --no-headers=true | awk '{print $6}')
do

  # Remove member from front end listeners for internal load balancers with Pool name 'ingress-http' and 'ingress-https'
  HTTP_MEMBER_ID=`ibmcloud is load-balancer-pool-members "${INTERNAL_LB_NAME}" "${HTTP_POOL}" | grep ${IP} | awk '{print $1}'`
  ibmcloud is load-balancer-pool-member-delete \
        "${INTERNAL_LB_NAME}" "${HTTP_POOL}" "${HTTP_MEMBER_ID}" --vpc "${VPC_NAME}" --output JSON

  wait_for_active_lb_state "$INTERNAL_LB_NAME"

  HTTPS_MEMBER_ID=`ibmcloud is load-balancer-pool-members "${INTERNAL_LB_NAME}" "${HTTPS_POOL}" | grep ${IP} | awk '{print $1}'`
  ibmcloud is load-balancer-pool-member-delete \
        "${INTERNAL_LB_NAME}" "${HTTPS_POOL}" "${HTTPS_MEMBER_ID}" --vpc "${VPC_NAME}" --output JSON

  # Remove member from front end listeners for external load balancers with Pool name 'ingress-http' and 'ingress-https'
  HTTP_MEMBER_ID=`ibmcloud is load-balancer-pool-members "${EXTERNAL_LB_NAME}" "${HTTP_POOL}" | grep ${IP} | awk '{print $1}'`
  ibmcloud is load-balancer-pool-member-delete \
        "${EXTERNAL_LB_NAME}" "${HTTP_POOL}" "${HTTP_MEMBER_ID}" --vpc "${VPC_NAME}" --output JSON

  wait_for_active_lb_state "$EXTERNAL_LB_NAME"

  HTTPS_MEMBER_ID=`ibmcloud is load-balancer-pool-members "${EXTERNAL_LB_NAME}" "${HTTPS_POOL}" | grep ${IP} | awk '{print $1}'`
  ibmcloud is load-balancer-pool-member-delete \
        "${EXTERNAL_LB_NAME}" "${HTTPS_POOL}" "${HTTPS_MEMBER_ID}" --vpc "${VPC_NAME}" --output JSON

done

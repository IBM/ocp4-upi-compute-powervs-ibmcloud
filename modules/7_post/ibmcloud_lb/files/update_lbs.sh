################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# The script updates the ibmcloud entries for the new Intel nodes pool
IBMCLOUD_API_KEY=$1
VPC_REGION=$2
RESOURCE_GROUP=$3
VPC_NAME=$4

# Dev Note: we want to refresh the credentials and not assume it's OK.
echo "Login to the IBM Cloud"
ibmcloud login --apikey ${IBMCLOUD_API_KEY} -r ${VPC_REGION} -g ${RESOURCE_GROUP}

# 1. Fetch IP addresses of newly added x86 workers
for IP in $(oc get nodes -lkubernetes.io/arch=amd64 -owide --no-headers=true | awk '{print $6}')
do
# Find the Load Balancer

# 2. Modify front end listeners for internal and external load balancers with Pool name 'ingress-http' and 'ingress-https'


# 3.Add Server Instances to above listeners


ibmcloud is vpc ${VPC_NAME} --output json
ibmcloud is load-balancers --resource-group-name ${RESOURCE_GROUP} --output json
--- figure out which ones are in the vpc 

1. GET THE INTERNAL IP.
oc get nodes -lkubernetes.io/arch=amd64 -owide --no-headers=true | awk '{print $6}'

LB=
POOL=
ibmcloud is load-balancer-pool-member-create \
	"${INGRESS_HTTP_LB}" "${HTTP_POOL}" 80 ${IP} --output JSON

ibmcloud is load-balancer-pool-member-create \
	"${INGRESS_HTTPS_LB}" "${HTTPS_POOL}" 443 ${IP} --output JSON

done

load-balancer-pools
load-balancer-pool-member-create, lb-pmc                                        Create a load balancer pool member
    load-balancer-pool-member-delete, lb-pmd                                        Delete one or more members from a load balancer pool.
    


    load-balancer, lb                                                               View details of a load balancer
    load-balancer-create, lbc                                                       Create a load balancer
    load-balancer-delete, lbd                                                       Delete one or more load balancers.
    load-balancer-listener, lb-l                                                    View details of a load balancer listener
    load-balancer-listener-create, lb-lc                                            Create a load balancer listener
    load-balancer-listener-delete, lb-ld                                            Delete one or more load balancer listeners.
    load-balancer-listener-policies, lb-lps                                         List all load balancer policies
    load-balancer-listener-policy, lb-lp                                            View details of load balancer listener policy
    load-balancer-listener-policy-create, lb-lpc                                    Create a load balancer listener policy
    load-balancer-listener-policy-delete, lb-lpd                                    Delete one or more policies from a load balancer listener.
    load-balancer-listener-policy-rule, lb-lpr                                      List single load balancer policy rule
    load-balancer-listener-policy-rule-create, lb-lprc                              Create a load balancer listener policy rule
    load-balancer-listener-policy-rule-delete, lb-lprd                              Delete one or more policies from a load balancer listener.
    load-balancer-listener-policy-rule-update, lb-lpru                              Update a rule of a load balancer listener policy
    load-balancer-listener-policy-rules, lb-lprs                                    List all load balancer policy rules
    load-balancer-listener-policy-update, lb-lpu                                    Update a policy of a load balancer listener
    load-balancer-listener-update, lb-lu                                            Update a load balancer listener
    load-balancer-listeners, lb-ls                                                  List all load balancer listeners
    load-balancer-pool, lb-p                                                        View details of a load balancer pool
    load-balancer-pool-create, lb-pc                                                Create a load balancer pool
    load-balancer-pool-delete, lb-pd                                                Delete one or more pools from a load balancer.
    load-balancer-pool-member, lb-pm                                                View details of load balancer pool member
    load-balancer-pool-member-create, lb-pmc                                        Create a load balancer pool member
    load-balancer-pool-member-delete, lb-pmd                                        Delete one or more members from a load balancer pool.
    load-balancer-pool-member-update, lb-pmu                                        Update a member of a load balancer pool
    load-balancer-pool-members, lb-pms                                              List all the members of a load balancer pool
    load-balancer-pool-members-update, lb-pmsu                                      Update members of the load balancer pool
    load-balancer-pool-update, lb-pu                                                Update a pool of a load balancer
    load-balancer-pools, lb-ps                                                      List all pools of a load balancer
    load-balancer-statistics, lb-statistics                                         List all statistics of a load balancer
    load-balancer-update, lbu                                                       Update a load balancer
    load-balancers, lbs       

ibmcloud is load-balancer-pool-members --vpc ${VPC_NAME}


ingress-https
ingress-http 
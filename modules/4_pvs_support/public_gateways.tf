################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Dev note: 
# 1 - Destroy - removes any work that's previously been applied using the stored log
# 2 - Create:
# - Searches for the VPC
# - For each one of the possible zones
#    - Check the Subnets in the Zone has a Public Gateway

# ibmcloud is subnets --output json | less   

# ibmcloud is public-gateway-delete 


# ibmcloud is public-gateway-create --resource-group-name --ip
#     ibmcloud is public-gateway-create my-public-gateway my-vpc us-south-1


# data "ibm_is_subnets" "sn" {
#   routing_table_name = data.ibm_is_vpc.vpc.default_routing_table_name
# }

# locals {

# }

# resource "ibm_is_public_gateway" "example" {
#   count = length(data.ibm_is_subnets.subnets.subnets)
#   name  = data.ibm_is_subnets.sn.subnets[count.index]
#   vpc   = ibm_is_vpc.example.id
#   zone  = "eu-gb-1"
# }

# resource "ibm_is_subnet_public_gateway_attachment" "example" {
#   subnet         = ibm_is_subnet.example.id
#   public_gateway = ibm_is_public_gateway.example.id
# }
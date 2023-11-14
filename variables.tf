################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# *Design Note*
# Global variables are prefixed with ibmcloud_
# PowerVS variables are prefixed with powervs_
# VPC variables are prefixed with vpc_

variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API key associated with user's identity"
  default     = "<key>"

  validation {
    condition     = var.ibmcloud_api_key != "<key>"
    error_message = "The api key is empty, check that the -var-file= is set properly"
  }
}

################################################################
# Configure the IBM PowerVS provider
################################################################

variable "powervs_service_instance_id" {
  type        = string
  description = "The PowerVS service instance ID of your account"
  default     = ""
}

variable "powervs_region" {
  type        = string
  description = "The IBM Cloud region where you want to create the workers"
  default     = ""
}

variable "powervs_zone" {
  type        = string
  description = "The zone of an IBM Cloud region where you want to create Power System workers"
  default     = ""
}

################################################################
# Configure the IBM VPC provider
################################################################

variable "vpc_name" {
  type        = string
  description = "The name of an IBM Cloud VPC where OCP cluster is running"
  default     = ""
}

variable "vpc_region" {
  type        = string
  description = "The region of an IBM Cloud VPC where OCP cluster is running"
  default     = ""
}

variable "vpc_zone" {
  type        = string
  description = "The zone of an IBM Cloud VPC where OCP cluster is running"
  default     = ""
}

# only used when you have vpc_create set
variable "vpc_resource_group" {
  type        = string
  description = "The resource group to create the vpc within"
  default     = ""
}

################################################################
# Configure the PowerVS instance bastion details
################################################################

variable "powervs_bastion_ip" {
  type        = string
  description = "The Bastion IP of the OpenShift Cluster on PowerVS"
  default     = ""
  validation {
    condition     = length(var.powervs_bastion_ip) > 0
    error_message = "The powervs_bastion_ip must exist."
  }
}

variable "powervs_bastion_private_ip" {
  type        = string
  description = "The Bastion private IP of the OpenShift Cluster on PowerVS"
  default     = ""
  validation {
    condition     = length(var.powervs_bastion_private_ip) > 0
    error_message = "The powervs_bastion_private_ip must exist."
  }
}

variable "powervs_network_name" {
  type        = string
  description = "The powervs network name where the cluster is installed"
  default     = "ocp-net"
  validation {
    condition     = length(var.powervs_network_name) > 0
    error_message = "The powervs_network_name value must be greater than 1."
  }
}

################################################################
# Configure the Intel workers to be added to the compute plane
################################################################

variable "worker_1" {
  type = object({ count = number, profile = string, zone = string })
  default = {
    count   = 1
    profile = "cx2-8x16"
    zone    = ""
  }
  validation {
    condition     = lookup(var.worker_1, "count", 1) >= 1
    error_message = "The worker.count value must be greater than 1."
  }
}

variable "worker_2" {
  type = object({ count = number, profile = string, zone = string })
  default = {
    count   = 0
    profile = "cx2-8x16"
    zone    = ""
  }
  validation {
    condition     = lookup(var.worker_2, "count", 1) >= 0
    error_message = "The worker.count value must be greater than 0."
  }
}

variable "worker_3" {
  type = object({ count = number, profile = string, zone = string })
  default = {
    count   = 0
    profile = "cx2-8x16"
    zone    = ""
  }
  validation {
    condition     = lookup(var.worker_3, "count", 1) >= 0
    error_message = "The worker.count value must be greater than 0."
  }
}

variable "create_custom_subnet" {
  type        = bool
  description = "creates the subnets, and will error out if the subnets exist"
  default     = false
}

variable "skip_transit_gateway_create" {
  type        = bool
  description = "skips the creation of the transit gateway"
  default     = false
}

################################################################
# PowerVS Network - Networking
################################################################

variable "powervs_machine_cidr" {
  type        = string
  description = "PowerVS DHCP Network cidr eg. 192.168.200.0/24"
  default     = "192.168.200.0/24"
}

################################################################
### OpenShift variables
################################################################

# Must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character
# Should not be more than 14 characters
variable "cluster_id_prefix" {
  type    = string
  default = "test-ocp"

  validation {
    condition     = can(regex("^$|^[a-z0-9]+[a-zA-Z0-9_\\-.]*[a-z0-9]+$", var.cluster_id_prefix))
    error_message = "The cluster_id_prefix value must be a lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character."
  }

  validation {
    condition     = length(var.cluster_id_prefix) <= 14
    error_message = "The cluster_id_prefix value shouldn't be greater than 14 characters."
  }
}
# Must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character
# Length cannot exceed 14 characters when combined with cluster_id_prefix
variable "cluster_id" {
  type    = string
  default = ""

  validation {
    condition     = can(regex("^$|^[a-z0-9]+[a-zA-Z0-9_\\-.]*[a-z0-9]+$", var.cluster_id))
    error_message = "The cluster_id value must be a lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character."
  }

  validation {
    condition     = length(var.cluster_id) <= 14
    error_message = "The cluster_id value shouldn't be greater than 14 characters."
  }
}

variable "use_zone_info_for_names" {
  type        = bool
  default     = true
  description = "Add zone info to instance name or not"
}

################################################################
# Additional Settings
################################################################
variable "ssh_agent" {
  type        = bool
  description = "Enable or disable SSH Agent. Can correct some connectivity issues. Default: false"
  default     = false
}

variable "connection_timeout" {
  description = "Timeout in minutes for SSH connections"
  default     = 30
}

variable "rhel_username" {
  type        = string
  description = "The username used to connect to the bastion"
  default     = "root"
}

variable "node_labels" {
  type        = map(string)
  description = "Map of node labels for the cluster nodes"
  default     = {}
}

##########################################

variable "public_key_file" {
  type        = string
  description = "Path to public key file"
  default     = "data/id_rsa.pub"
  # if empty, will default to ${path.cwd}/data/id_rsa.pub
}

variable "private_key_file" {
  type        = string
  description = "Path to private key file"
  default     = "data/id_rsa"
  # if empty, will default to ${path.cwd}/data/id_rsa
}

variable "private_key" {
  type        = string
  description = "content of private ssh key"
  default     = ""
  # if empty, will read contents of file at var.private_key_file
}

variable "public_key" {
  type        = string
  description = "Public key"
  default     = ""
  # if empty, will read contents of file at var.public_key_file
}

###
variable "name_prefix" {
  type    = string
  default = ""
  validation {
    condition     = length(var.name_prefix) <= 32
    error_message = "Length cannot exceed 32 characters for name_prefix."
  }
}

variable "node_prefix" {
  type    = string
  default = ""
  validation {
    condition     = length(var.node_prefix) <= 32
    error_message = "Length cannot exceed 32 characters for node_prefix."
  }
}

###
locals {
  private_key_file = var.private_key_file == "" ? "${path.cwd}/data/id_rsa" : var.private_key_file
  public_key_file  = var.public_key_file == "" ? "${path.cwd}/data/id_rsa.pub" : var.public_key_file
  private_key      = var.private_key == "" ? file(coalesce(local.private_key_file, "/dev/null")) : var.private_key
  public_key       = var.public_key == "" ? file(coalesce(local.public_key_file, "/dev/null")) : var.public_key
}

################################################################
# Overrides the Region Check
################################################################

variable "override_region_check" {
  type        = bool
  description = "Set to true if you want to skip region checks."
  default     = false
}

################################################################
# Supports the CICD features
################################################################

variable "cicd_image_pruner_cleanup" {
  type        = bool
  description = "Cleans up image pruner jobs"
  default     = false
}

variable "skip_authorization_policy_create" {
  type        = bool
  description = "Skips trying to create the authorization policy for the Image Service for VPC's access to COS"
  default     = false
}

variable "vpc_create" {
  type        = bool
  description = "creates the vpc with the given name"
  default     = false
}

variable "vpc_skip_ssh_key_create" {
  type        = bool
  description = "skips the creation of the ssh keys in the vpc environment"
  default     = false
}

variable "skip_create_security_group" {
  type        = bool
  description = "skips the creation of the security group in a vpc environment"
  default     = false
}


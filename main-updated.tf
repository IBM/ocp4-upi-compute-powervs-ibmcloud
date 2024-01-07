# Consolidated variables for better organization
variable "common_vars" {
  type = object({
    private_key_file = string
    ssh_agent = bool
    connection_timeout = number
    rhel_username = string
    bastion_public_ip = string
  })
}

# ... other variables (unchanged)

provider "ibm" {
  alias = "vpc"
  # ... other configuration (unchanged)
}

provider "ibm" {
  alias = "powervs"
  # ... other configuration (unchanged)
}

# ... other resources (unchanged)

module "vpc" {
  # ... module configuration
}

module "vpc_prepare" {
  providers = {
    ibm = ibm.vpc
  }
  depends_on = [module.vpc]
  source = "./modules/1_vpc_prepare"

  # Using outputs from vpc module for better modularity
  vpc_name = module.vpc.vpc_name
  vpc_region = module.vpc.vpc_region
  resource_group = module.vpc.vpc_resource_group

  # Passing common variables as a single structure
  common_vars = var.common_vars

  # ... other module configuration (unchanged)
}

# ... other modules with similar adjustments (unchanged)

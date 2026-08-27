terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azapi" {}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

# This is required for resource modules
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  location = local.selected_region
  name     = module.naming.resource_group.name_unique
}

module "vnet" {
  source = "../../"

  location         = module.resource_group.location
  parent_id        = module.resource_group.resource_id
  address_space    = ["10.0.0.0/16"]
  enable_telemetry = true
  name             = module.naming.virtual_network.name
  subnets = {
    subnet1 = {
      name                            = "subnet1"
      address_prefix                  = "10.0.0.0/24"
      default_outbound_access_enabled = true
      delegations = [{
        name = "aca_delegation"
        service_delegation = {
          name = "Microsoft.App/environments"
        }
      }]
    }
  }
}

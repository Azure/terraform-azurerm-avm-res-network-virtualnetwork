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

resource "azapi_resource" "local" {
  location  = module.resource_group.location
  name      = "${module.naming.virtual_network.name_unique}-1"
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
      }
    }
  }
  response_export_values = []
}

resource "azapi_resource" "remote" {
  location  = module.resource_group.location
  name      = "${module.naming.virtual_network.name_unique}-2"
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.1.0.0/16"]
      }
    }
  }
  response_export_values = []
}

module "peering" {
  source = "../../modules/peering"

  name                                 = "${module.naming.virtual_network_peering.name_unique}-local-to-remote"
  parent_id                            = azapi_resource.local.id
  remote_virtual_network_id            = azapi_resource.remote.id
  allow_forwarded_traffic              = true
  allow_gateway_transit                = true
  allow_virtual_network_access         = true
  create_reverse_peering               = true
  reverse_allow_forwarded_traffic      = false
  reverse_allow_gateway_transit        = false
  reverse_allow_virtual_network_access = true
  reverse_name                         = "${module.naming.virtual_network_peering.name_unique}-remote-to-local"
  reverse_use_remote_gateways          = false
  use_remote_gateways                  = false
}

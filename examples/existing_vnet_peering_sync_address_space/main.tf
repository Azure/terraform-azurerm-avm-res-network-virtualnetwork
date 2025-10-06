terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.2"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_virtual_network" "local" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_network.name_unique}-1"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"] # Original single address space
}

resource "azurerm_virtual_network" "remote" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_network.name_unique}-2"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.1.0.0/16"]
}

module "peering" {
  source = "../../modules/peering"

  name                                 = "${module.naming.virtual_network_peering.name_unique}-local-to-remote"
  parent_id                            = azurerm_virtual_network.local.id
  remote_virtual_network_id            = azurerm_virtual_network.remote.id
  allow_forwarded_traffic              = true
  allow_gateway_transit                = true
  allow_virtual_network_access         = true
  create_reverse_peering               = true
  reverse_allow_forwarded_traffic      = false
  reverse_allow_gateway_transit        = false
  reverse_allow_virtual_network_access = true
  reverse_name                         = "${module.naming.virtual_network_peering.name_unique}-remote-to-local"
  reverse_use_remote_gateways          = false
  sync_remote_address_space            = true
  use_remote_gateways                  = false
}


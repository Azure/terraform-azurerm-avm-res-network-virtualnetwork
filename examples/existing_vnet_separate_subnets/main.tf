terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
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
  source  = "Azure/regions/azurerm"
  version = "~> 0.3"
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
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_virtual_network" "this" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

# illustrates how to make subnets separately to deal with <https://github.com/Azure/terraform-provider-azapi/issues/503>
module "existing_vnet_subnet0" {
  source = "../../"
  existing_vnet = {
    id = azurerm_virtual_network.this.id
  }
  # note the resource group for the subnet comes from the existing_vnet id, but this is kept so that the intention is explicit.
  resource_group_name = azurerm_resource_group.this.name
  subnets = {
    snet0 = {
      name             = "snet0"
      address_prefixes = ["10.0.0.0/24"]
    }
  }
  location = azurerm_resource_group.this.location
}

module "existing_vnet_subnet1" {
  source = "../../"
  existing_vnet = {
    id = azurerm_virtual_network.this.id
  }
  # note the resource group for the subnet comes from the existing_vnet id, but this is kept so that the intention is explicit.
  resource_group_name = azurerm_resource_group.this.name
  subnets = {
    snet1 = {
      name             = "snet1"
      address_prefixes = ["10.0.1.0/24"]
    }
  }
  location = azurerm_resource_group.this.location
}

terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.9"
    }
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

data "azurerm_subscription" "this" {}

resource "azapi_resource" "network_manager" {
  type = "Microsoft.Network/networkManagers@2024-03-01"
  body = {
    properties = {
      networkManagerScopeAccesses = []
      networkManagerScopes = {
        subscriptions = [data.azurerm_subscription.this.id]
      }
    }
  }
  location                  = module.regions.regions[random_integer.region_index.result].name
  name                      = replace(module.naming.resource_group.name_unique, module.naming.resource_group.slug, "avnm")
  parent_id                 = azurerm_resource_group.this.id
  schema_validation_enabled = false
}

resource "azapi_resource" "pool" {
  type = "Microsoft.Network/networkManagers/ipamPools@2024-01-01-preview"
  body = {
    properties = {
      addressPrefixes = ["10.0.0.0/16"]
      description     = "Example IPAM Pool"
      displayName     = "Example IPAM Pool"
    }
  }
  location                  = module.regions.regions[random_integer.region_index.result].name
  name                      = "example_ipam_pool"
  parent_id                 = azapi_resource.network_manager.id
  schema_validation_enabled = false
}

resource "azurerm_network_security_group" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.network_security_group.name
  resource_group_name = azurerm_resource_group.this.name
}

# Creating a virtual network with a unique name, telemetry settings, and in the specified resource group and location.
module "vnet" {
  source              = "../../"
  name                = module.naming.virtual_network.name
  enable_telemetry    = true
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  ipam_pool = {
    id                  = azapi_resource.pool.id
    number_of_addresses = 256
  }

  subnets = {
    bravo = {
      name                = "subnet2"
      address_prefix_size = 26
      network_security_group = {
        id = azurerm_network_security_group.this.id
      }
    }
    alpha = {
      name                = "subnet1"
      address_prefix_size = 25
      network_security_group = {
        id = azurerm_network_security_group.this.id
      }
    }
    charlie = {
      name                = "subnet3"
      address_prefix_size = 26
      network_security_group = {
        id = azurerm_network_security_group.this.id
      }
    }
  }
}

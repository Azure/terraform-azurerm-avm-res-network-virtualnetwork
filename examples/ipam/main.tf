terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
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
# * IPAM is not in all regions *
# module "regions" {
#   source  = "Azure/regions/azurerm"
#   version = "~> 0.3"
# }
locals {
  regions = [
    "eastus2",
    "westus2",
    "eastus",
    "westeurope",
    "uksouth",
    "northeurope",
    "centralus",
    "australiaeast",
    "westus",
    "southcentralus",
    "francecentral",
    "southafricanorth",
    "swedencentral",
    "centralindia",
    "eastasia",
    "canadacentral",
    "germanywestcentral",
    "italynorth",
    "norwayeast",
    "polandcentral",
    "switzerlandnorth",
    "uaenorth",
    "brazilsouth",
    "israelcentral",
    "northcentralus",
    "australiacentral",
    "australiacentral2",
    "australiasoutheast",
    "southindia",
    "canadaeast",
    "francesouth",
    "germanynorth",
    "norwaywest",
    "switzerlandwest",
    "ukwest",
    "uaecentral",
    "brazilsoutheast",
    "mexicocentral",
    "spaincentral",
    "japaneast",
    "koreasouth",
    "koreacentral",
    "newzealandnorth",
    "southeastasia",
    "japanwest",
    "westcentralus"
  ]
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.regions) - 1
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
  location = local.regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

data "azurerm_subscription" "this" {}

# Create a network manager and an IPAM pool
resource "azapi_resource" "network_manager" {
  location  = azurerm_resource_group.this.location
  name      = replace(module.naming.resource_group.name_unique, module.naming.resource_group.slug, "avnm")
  parent_id = azurerm_resource_group.this.id
  type      = "Microsoft.Network/networkManagers@2024-07-01"
  body = {
    properties = {
      networkManagerScopeAccesses = []
      networkManagerScopes = {
        subscriptions = [data.azurerm_subscription.this.id]
      }
    }
  }
  schema_validation_enabled = false
}

# Wait for pools to be cleaned up before destroying the network manager
resource "time_sleep" "wait_30_seconds" {
  destroy_duration = "30s"

  depends_on = [azapi_resource.network_manager]
}

resource "azapi_resource" "pool_v4" {
  location  = azurerm_resource_group.this.location
  name      = "example_ipam_pool_v4"
  parent_id = azapi_resource.network_manager.id
  type      = "Microsoft.Network/networkManagers/ipamPools@2024-07-01"
  body = {
    properties = {
      addressPrefixes = ["10.0.0.0/16"]
      description     = "Example IPAM Pool v4"
      displayName     = "Example IPAM Pool v4"
    }
  }
  schema_validation_enabled = false

  depends_on = [time_sleep.wait_30_seconds]
}

resource "azapi_resource" "pool_v6" {
  location  = azurerm_resource_group.this.location
  name      = "example_ipam_pool_v6"
  parent_id = azapi_resource.network_manager.id
  type      = "Microsoft.Network/networkManagers/ipamPools@2024-07-01"
  body = {
    properties = {
      addressPrefixes = ["fdea:5251:1c0a::/48"]
      description     = "Example IPAM Pool v6"
      displayName     = "Example IPAM Pool v6"
    }
  }
  schema_validation_enabled = false

  depends_on = [time_sleep.wait_30_seconds]
}

resource "azurerm_network_security_group" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.network_security_group.name
  resource_group_name = azurerm_resource_group.this.name
}

# Creating a virtual network with a unique name, telemetry settings, and in the specified resource group and location.
module "vnet" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = true
  ipam_pools = [
    {
      id            = azapi_resource.pool_v4.id
      prefix_length = 24
    },
    {
      id            = azapi_resource.pool_v6.id
      prefix_length = 63
    }
  ]
  name = module.naming.virtual_network.name
  subnets = {
    subnet1 = {
      name = "subnet1"
      ipam_pools = [
        {
          id            = azapi_resource.pool_v4.id
          prefix_length = 25
        },
        {
          id            = azapi_resource.pool_v6.id
          prefix_length = 64
        }
      ]
      network_security_group = {
        id = azurerm_network_security_group.this.id
      }
    },
    subnet2 = {
      name = "subnet2"
      ipam_pools = [
        {
          id            = azapi_resource.pool_v4.id
          prefix_length = 25
        },
        {
          id            = azapi_resource.pool_v6.id
          prefix_length = 64
        }
      ]
      network_security_group = {
        id = azurerm_network_security_group.this.id
      }
    }
  }
}

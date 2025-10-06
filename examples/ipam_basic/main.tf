terraform {
  required_version = ">= 1.9.2"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
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
    "israelcentral"
  ]
}

resource "random_integer" "region_index" {
  max = length(local.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

resource "azurerm_resource_group" "this" {
  location = local.regions[random_integer.region_index.result]
  name     = "${module.naming.resource_group.name_unique}-retry-test"
}

data "azurerm_subscription" "this" {}

# Create Network Manager and IPAM Pool
resource "azapi_resource" "network_manager" {
  location  = azurerm_resource_group.this.location
  name      = replace(azurerm_resource_group.this.name, "rg-", "avnm-")
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
  retry = {
    interval_seconds     = 10
    max_interval_seconds = 180
    error_message_regex  = ["CannotDeleteResource", "Cannot delete resource while nested resources exist"]
  }
  schema_validation_enabled = false
}

resource "azapi_resource" "ipam_pool" {
  location  = azurerm_resource_group.this.location
  name      = "pool-retry-test"
  parent_id = azapi_resource.network_manager.id
  type      = "Microsoft.Network/networkManagers/ipamPools@2024-07-01"
  body = {
    properties = {
      addressPrefixes = ["10.0.0.0/16"]
      description     = "IPAM Pool for testing retry logic with multiple simultaneous subnet allocations"
      displayName     = "Retry Test Pool"
    }
  }
  retry = {
    interval_seconds     = 10
    max_interval_seconds = 180
    error_message_regex  = ["BadRequest", "Ipam pool.*has Azure resources associated"]
  }
  schema_validation_enabled = false

  depends_on = [azapi_resource.network_manager]
}

# TEST: Multiple IPAM subnets created simultaneously (no time delays)
# This should trigger the error we want to capture and handle with retry logic
module "vnet_retry_test" {
  source = "../../"

  location         = azurerm_resource_group.this.location
  parent_id        = azurerm_resource_group.this.id
  enable_telemetry = true
  # VNet gets address space from IPAM pool
  ipam_pools = [{
    id            = azapi_resource.ipam_pool.id
    prefix_length = 24 # /24 VNet (256 IP addresses)
  }]
  name = "${module.naming.virtual_network.name_unique}-retry-test"
  # Multiple IPAM subnets - this should test the retry logic
  subnets = {
    # All these will try to allocate simultaneously
    subnet1 = {
      name = "subnet1-retry-test"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26 # /26 (64 addresses)
      }]
    }
    subnet2 = {
      name = "subnet2-retry-test"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26 # /26 (64 addresses) - may overlap with subnet1 initially
      }]
    }
    subnet3 = {
      name = "subnet3-retry-test"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 27 # /27 (32 addresses)
      }]
    }
    subnet4 = {
      name = "subnet4-retry-test"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 27 # /27 (32 addresses)
      }]
    }
  }
}

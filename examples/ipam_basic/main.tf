terraform {
  required_version = ">= 1.9.2"

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

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  location = local.selected_region
  name     = "${module.naming.resource_group.name_unique}-retry-test"
}

data "azapi_client_config" "current" {}

# Create Network Manager and IPAM Pool
resource "azapi_resource" "network_manager" {
  location  = module.resource_group.location
  name      = replace(module.resource_group.name, "rg-", "avnm-")
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/networkManagers@2024-07-01"
  body = {
    properties = {
      networkManagerScopeAccesses = []
      networkManagerScopes = {
        subscriptions = ["/subscriptions/${data.azapi_client_config.current.subscription_id}"]
      }
    }
  }
  retry = {
    interval_seconds     = 10
    max_interval_seconds = 180
    error_message_regex  = ["CannotDeleteResource", "Cannot delete resource while nested resources exist"]
  }
  response_export_values    = []
  schema_validation_enabled = false
}

resource "azapi_resource" "ipam_pool" {
  location  = module.resource_group.location
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
  response_export_values    = []
  schema_validation_enabled = false

  depends_on = [azapi_resource.network_manager]
}

# TEST: Multiple IPAM subnets created simultaneously (no time delays)
# This should trigger the error we want to capture and handle with retry logic
module "vnet_retry_test" {
  source = "../../"

  location         = module.resource_group.location
  parent_id        = module.resource_group.resource_id
  enable_telemetry = true
  # VNet gets address space from IPAM pool
  ipam_pools = [{
    id                     = azapi_resource.ipam_pool.id
    number_of_ip_addresses = "256"
  }]
  name = "${module.naming.virtual_network.name_unique}-retry-test"
  # Multiple IPAM subnets - this should test the retry logic
  subnets = {
    # All these will try to allocate simultaneously
    subnet1 = {
      name = "subnet1-retry-test"
      ipam_pools = [{
        pool_id                = azapi_resource.ipam_pool.id
        number_of_ip_addresses = "64"
      }]
    }
    subnet2 = {
      name = "subnet2-retry-test"
      ipam_pools = [{
        pool_id                = azapi_resource.ipam_pool.id
        number_of_ip_addresses = "64"
      }]
    }
    subnet3 = {
      name = "subnet3-retry-test"
      ipam_pools = [{
        pool_id                = azapi_resource.ipam_pool.id
        number_of_ip_addresses = "32"
      }]
    }
    subnet4 = {
      name = "subnet4-retry-test"
      ipam_pools = [{
        pool_id                = azapi_resource.ipam_pool.id
        number_of_ip_addresses = "32"
      }]
    }
  }
}

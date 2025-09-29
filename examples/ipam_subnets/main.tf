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

locals {
  regions = ["eastus2"] # IPAM available regions
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
  name     = module.naming.resource_group.name_unique
}

data "azurerm_subscription" "this" {}

# Create Network Manager and IPAM Pool
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

resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"

  depends_on = [azapi_resource.network_manager]
}

resource "azapi_resource" "ipam_pool" {
  location  = azurerm_resource_group.this.location
  name      = "ipam-pool-subnets-test"
  parent_id = azapi_resource.network_manager.id
  type      = "Microsoft.Network/networkManagers/ipamPools@2024-07-01"
  body = {
    properties = {
      addressPrefixes = ["10.0.0.0/16"]
      description     = "IPAM Pool for testing time-delayed subnet allocation"
      displayName     = "IPAM Pool - Subnet Test"
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

# 🆕 TEST: VNet with IPAM subnets using time delays and dependency management
# Features demonstrated:
# - Sequential IPAM subnet creation with configurable delays
# - Enhanced retry configuration for AnotherOperationInProgress errors
# - Non-IPAM subnets wait for IPAM operations to complete
# - Comprehensive error handling for Azure networking operations
module "vnet_ipam_subnets" {
  source = "../../"

  location         = azurerm_resource_group.this.location
  parent_id        = azurerm_resource_group.this.id
  enable_telemetry = true
  # Configure VNet to use IPAM for address space
  ipam_pools = [{
    id            = azapi_resource.ipam_pool.id
    prefix_length = 24 # /24 for the VNet
  }]
  # Configurable delay between IPAM subnet allocations
  ipam_subnet_allocation_delay = 45 # 45 seconds between each subnet
  name                         = "${module.naming.virtual_network.name_unique}-ipam-subnets"
  # Multiple subnets using IPAM allocation (will be created sequentially)
  subnets = {
    # First subnet (no delay)
    subnet1 = {
      name = "subnet1-ipam"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26 # /26 from the pool
      }]
      network_security_group = {
        id = azurerm_network_security_group.this.id
      }
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }

    # Second subnet (45s delay)
    subnet2 = {
      name = "subnet2-ipam"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26 # /26 from the pool
      }]
      network_security_group = {
        id = azurerm_network_security_group.this.id
      }
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }

    # Third subnet (90s delay)
    subnet3 = {
      name = "subnet3-ipam"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 27 # /27 from the pool
      }]
      network_security_group = {
        id = azurerm_network_security_group.this.id
      }
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }

    # Mixed: Explicit subnet (waits for IPAM subnets to complete)
    # This subnet uses explicit addressing but will wait for all IPAM operations
    # to complete before being created, preventing AnotherOperationInProgress errors
    explicit_subnet = {
      name             = "explicit-subnet"
      address_prefixes = ["10.0.0.192/26"] # Within the IPAM-allocated VNet range
      network_security_group = {
        id = azurerm_network_security_group.this.id
      }
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }
  }
}

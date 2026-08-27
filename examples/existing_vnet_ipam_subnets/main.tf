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

  location = local.selected_region.name
  name     = module.naming.resource_group.name_unique
}

data "azapi_client_config" "current" {}

# Network Manager and IPAM Pool
resource "azapi_resource" "network_manager" {
  location  = module.resource_group.location
  name      = replace(module.naming.resource_group.name_unique, module.naming.resource_group.slug, "avnm")
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
  name      = "pool-subnet-test"
  parent_id = azapi_resource.network_manager.id
  type      = "Microsoft.Network/networkManagers/ipamPools@2024-07-01"
  body = {
    properties = {
      addressPrefixes = ["10.0.0.0/16"]
      description     = "IPAM Pool for standalone subnet module testing"
      displayName     = "Subnet Test Pool"
    }
  }
  retry = {
    interval_seconds     = 10
    max_interval_seconds = 180
    error_message_regex  = ["BadRequest", "Ipam pool.*has Azure resources associated"]
  }
  response_export_values    = []
  schema_validation_enabled = true
}

# Create VNet with IPAM addressing (REQUIRED for IPAM subnets)
# NOTE: In production, you would typically reference an existing IPAM-enabled VNet
# using data sources rather than creating a new one
module "ipam_vnet" {
  source = "../../"

  location         = module.resource_group.location
  parent_id        = module.resource_group.resource_id
  enable_telemetry = true
  # VNet gets address space from IPAM pool
  ipam_pools = [{
    id            = azapi_resource.ipam_pool.id
    prefix_length = 16 # /16 VNet (65,536 IP addresses)
  }]
  name = "${module.naming.virtual_network.name_unique}-ipam-test"
  tags = {
    Environment = "test"
    Purpose     = "ipam-subnet-module-demo"
  }
}

resource "azapi_resource" "app" {
  location  = module.resource_group.location
  name      = "${module.naming.network_security_group.name}-app"
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/networkSecurityGroups@2024-07-01"
  body = {
    properties = {
      securityRules = [{
        name = "AllowHTTP"
        properties = {
          access                   = "Allow"
          destinationAddressPrefix = "*"
          destinationPortRanges    = ["80", "443"]
          direction                = "Inbound"
          priority                 = 1001
          protocol                 = "Tcp"
          sourceAddressPrefix      = "*"
          sourcePortRange          = "*"
        }
      }]
    }
  }
  response_export_values = []
}

# Test: Create IPAM subnet using the standalone subnet module
module "ipam_subnet" {
  source = "../../modules/subnet"

  name      = "subnet-ipam-test"
  parent_id = module.ipam_vnet.resource_id
  # IPAM allocation
  ipam_pools = [{
    pool_id       = azapi_resource.ipam_pool.id
    prefix_length = 24 # /24 subnet (256 IP addresses)
  }]
  network_security_group = {
    id = azapi_resource.app.id
  }
  service_endpoints = ["Microsoft.Storage"]
}

# Test: Create traditional subnet using the same module
# Note: Traditional subnets can coexist with IPAM subnets in IPAM-enabled VNets
module "traditional_subnet" {
  source = "../../modules/subnet"

  name             = "subnet-traditional-test"
  parent_id        = module.ipam_vnet.resource_id
  address_prefixes = ["10.0.1.0/24"] # Must be within the IPAM-allocated VNet space
  network_security_group = {
    id = azapi_resource.app.id
  }
  service_endpoints = ["Microsoft.KeyVault"]
}

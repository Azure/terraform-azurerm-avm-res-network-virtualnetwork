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

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
# IPAM is not yet supported in all regions, therfore commenting out module "regions"
# IPAM NOT supported in these regions:
# "austriaeast",      # Austria East
# "chilecentral",     # Chile Central
# "chinaeast",        # China East
# "chinanorth",       # China North
# "indonesiacentral", # Indonesia Central
# "malaysiawest",     # Malaysia West
# "mexicocentral",    # Mexico Central
# "newzealandnorth",  # New Zealand North
# "spaincentral"      # Spain Central

# module "regions" {
#   source  = "Azure/regions/azurerm"
#   version = "~> 0.3"
# }

locals {
  # Regions where IPAM is officially supported
  # Source: Microsoft Learn documentation for Azure Virtual Network Manager IPAM
  # Excludes regions officially listed as unsupported by Microsoft
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
    "westcentralus",
    "austriaeast"
    # EXCLUDED per Microsoft documentation (IPAM not supported):
    # - "chilecentral", "jioindiawest", "malaysiawest"
    # - "qatarcentral", "southafricawest", "westindia", "westus3"
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
  name     = module.naming.resource_group.name_unique
}

data "azurerm_subscription" "this" {}

# Network Manager and IPAM Pool
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
  retry = {
    interval_seconds     = 10
    max_interval_seconds = 180
    error_message_regex  = ["CannotDeleteResource", "Cannot delete resource while nested resources exist"]
  }
  schema_validation_enabled = false
}



resource "azapi_resource" "ipam_pool" {
  location  = azurerm_resource_group.this.location
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
  schema_validation_enabled = true
}

# Create VNet with IPAM addressing (REQUIRED for IPAM subnets)
# NOTE: In production, you would typically reference an existing IPAM-enabled VNet
# using data sources rather than creating a new one
module "ipam_vnet" {
  source = "../../"

  location         = azurerm_resource_group.this.location
  parent_id        = azurerm_resource_group.this.id
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

resource "azurerm_network_security_group" "app" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.network_security_group.name}-app"
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_ranges    = ["80", "443"]
    direction                  = "Inbound"
    name                       = "AllowHTTP"
    priority                   = 1001
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
  }
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
    id = azurerm_network_security_group.app.id
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
    id = azurerm_network_security_group.app.id
  }
  service_endpoints = ["Microsoft.KeyVault"]
}

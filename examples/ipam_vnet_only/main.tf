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
    "westcentralus"
    # IPAM NOT supported in these regions:
    # "austriaeast",      # Austria East
    # "belgiumcentral",   # Belgium Central
    # "chilecentral",     # Chile Central
    # "chinaeast",        # China East
    # "chinanorth",       # China North
    # "francesouth",      # France South (use francecentral)
    # "indonesiacentral", # Indonesia Central
    # "malaysiawest",     # Malaysia West
    # "qatarcentral",     # Qatar Central
    # "southafricawest",  # South Africa West (use southafricanorth)
    # "westindia",        # West India
    # "westus3"           # West US 3 (Network Manager supported, IPAM pools not)
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

# Create Network Manager for IPAM
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



# IPAM Pool for VNet address space only
resource "azapi_resource" "ipam_pool" {
  location  = azurerm_resource_group.this.location
  name      = "pool-vnet-only"
  parent_id = azapi_resource.network_manager.id
  type      = "Microsoft.Network/networkManagers/ipamPools@2024-07-01"
  body = {
    properties = {
      addressPrefixes = ["172.16.0.0/12"] # Private range for VNet allocation
      description     = "IPAM Pool for VNet address space allocation only"
      displayName     = "VNet Only Pool"
    }
  }
  retry = {
    interval_seconds     = 10
    max_interval_seconds = 180
    error_message_regex  = ["BadRequest", "Ipam pool.*has Azure resources associated"]
  }
  schema_validation_enabled = false

  depends_on = [azapi_resource.ipam_pool]
}

# Network Security Groups for traditional subnets
resource "azurerm_network_security_group" "web" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.network_security_group.name}-web"
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "80"
    direction                  = "Inbound"
    name                       = "AllowHTTP"
    priority                   = 1001
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
  }
}

resource "azurerm_network_security_group" "app" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.network_security_group.name}-app"
  resource_group_name = azurerm_resource_group.this.name
}

# VNet with IPAM address space allocation but traditional subnet addressing
module "vnet_ipam_traditional_subnets" {
  source = "../../"

  location  = azurerm_resource_group.this.location
  parent_id = azurerm_resource_group.this.id
  # DNS servers configuration
  dns_servers = {
    dns_servers = toset(["1.1.1.1", "8.8.8.8"])
  }
  enable_telemetry = true
  # VNet address space allocated from IPAM pool
  ipam_pools = [{
    id            = azapi_resource.ipam_pool.id
    prefix_length = 16 # /16 VNet from the /12 pool
  }]
  name = "${module.naming.virtual_network.name_unique}-ipam-vnet"
  # Traditional subnets with static addressing (IPAM VNet gets dynamic space)
  subnets = {
    # Static addressing - these addresses will work within common IPAM allocations
    web = {
      name             = "subnet-web"
      address_prefixes = ["172.16.0.0/24"] # First /24 in common /16 IPAM range
      network_security_group = {
        id = azurerm_network_security_group.web.id
      }
      service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
    }

    app = {
      name             = "subnet-app"
      address_prefixes = ["172.16.1.0/24"] # Second /24 in common /16 IPAM range
      network_security_group = {
        id = azurerm_network_security_group.app.id
      }
      service_endpoints = ["Microsoft.Storage"]
    }

    data = {
      name             = "subnet-data"
      address_prefixes = ["172.16.2.0/25"] # /25 in common /16 IPAM range
      network_security_group = {
        id = azurerm_network_security_group.app.id
      }
    }

    # Small management subnet at end of range
    management = {
      name             = "subnet-management"
      address_prefixes = ["172.16.255.240/28"] # Small management subnet
      network_security_group = {
        id = azurerm_network_security_group.app.id
      }
    }
  }
  tags = {
    Environment = "test"
    Purpose     = "ipam-vnet-only-demo"
    Scenario    = "ipam-vnet-traditional-subnets"
  }
}

# Demonstrate adding subnet to IPAM VNet using subnet module
module "additional_subnet" {
  source = "../../modules/subnet"

  name      = "subnet-additional"
  parent_id = module.vnet_ipam_traditional_subnets.resource_id
  # Use a specific address prefix within the IPAM-allocated VNet space
  address_prefixes = ["172.16.2.128/27"] # /27 in the expected IPAM range
  network_security_group = {
    id = azurerm_network_security_group.app.id
  }
  service_endpoints = ["Microsoft.KeyVault"]

  depends_on = [module.vnet_ipam_traditional_subnets]
}

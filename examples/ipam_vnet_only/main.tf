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

# Create Network Manager for IPAM
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

# IPAM Pool for VNet address space only
resource "azapi_resource" "ipam_pool" {
  location  = module.resource_group.location
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
  response_export_values    = []
  schema_validation_enabled = false

  depends_on = [azapi_resource.network_manager]
}

# Network Security Groups for traditional subnets
resource "azapi_resource" "web" {
  location  = module.resource_group.location
  name      = "${module.naming.network_security_group.name}-web"
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/networkSecurityGroups@2024-07-01"
  body = {
    properties = {
      securityRules = [{
        name = "AllowHTTP"
        properties = {
          access                   = "Allow"
          destinationAddressPrefix = "*"
          destinationPortRange     = "80"
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

resource "azapi_resource" "app" {
  location  = module.resource_group.location
  name      = "${module.naming.network_security_group.name}-app"
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/networkSecurityGroups@2024-07-01"
  body = {
    properties = {}
  }
  response_export_values = []
}

# VNet with IPAM address space allocation but traditional subnet addressing
module "vnet_ipam_traditional_subnets" {
  source = "../../"

  location  = module.resource_group.location
  parent_id = module.resource_group.resource_id
  # DNS servers configuration
  dns_servers = {
    dns_servers = toset(["1.1.1.1", "8.8.8.8"])
  }
  enable_telemetry = true
  # VNet address space allocated from IPAM pool
  ipam_pools = [{
    id                     = azapi_resource.ipam_pool.id
    number_of_ip_addresses = "65536" # /16 VNet from the /12 pool
  }]
  name = "${module.naming.virtual_network.name_unique}-ipam-vnet"
  # Traditional subnets with static addressing (IPAM VNet gets dynamic space)
  subnets = {
    # Static addressing - these addresses will work within common IPAM allocations
    web = {
      name             = "subnet-web"
      address_prefixes = ["172.16.0.0/24"] # First /24 in common /16 IPAM range
      network_security_group = {
        id = azapi_resource.web.id
      }
      service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
    }

    app = {
      name             = "subnet-app"
      address_prefixes = ["172.16.1.0/24"] # Second /24 in common /16 IPAM range
      network_security_group = {
        id = azapi_resource.app.id
      }
      service_endpoints = ["Microsoft.Storage"]
    }

    data = {
      name             = "subnet-data"
      address_prefixes = ["172.16.2.0/25"] # /25 in common /16 IPAM range
      network_security_group = {
        id = azapi_resource.app.id
      }
    }

    # Small management subnet at end of range
    management = {
      name             = "subnet-management"
      address_prefixes = ["172.16.255.240/28"] # Small management subnet
      network_security_group = {
        id = azapi_resource.app.id
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
    id = azapi_resource.app.id
  }
  service_endpoints = ["Microsoft.KeyVault"]

  depends_on = [module.vnet_ipam_traditional_subnets]
}

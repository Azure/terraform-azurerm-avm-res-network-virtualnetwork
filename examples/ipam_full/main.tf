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

# IPAM is available in limited regions
locals {
  regions = ["eastus2", "westus2", "westeurope"]
}

resource "random_integer" "region_index" {
  max = length(local.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
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
  schema_validation_enabled = false
}

# Allow time for network manager to be ready
resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"

  depends_on = [azapi_resource.network_manager]
}

# Create IPAM Pools
resource "azapi_resource" "ipam_pool_v4" {
  location  = azurerm_resource_group.this.location
  name      = "pool-ipv4-main"
  parent_id = azapi_resource.network_manager.id
  type      = "Microsoft.Network/networkManagers/ipamPools@2024-07-01"
  body = {
    properties = {
      addressPrefixes = ["10.0.0.0/14"] # Large pool for multiple VNets
      description     = "Main IPv4 IPAM Pool for comprehensive testing"
      displayName     = "IPv4 Main Pool"
    }
  }
  schema_validation_enabled = false

  depends_on = [time_sleep.wait_30_seconds]
}

resource "azapi_resource" "ipam_pool_v6" {
  location  = azurerm_resource_group.this.location
  name      = "pool-ipv6-main"
  parent_id = azapi_resource.network_manager.id
  type      = "Microsoft.Network/networkManagers/ipamPools@2024-07-01"
  body = {
    properties = {
      addressPrefixes = ["fdea:5251:1c0a::/48"]
      description     = "IPv6 IPAM Pool for dual-stack testing"
      displayName     = "IPv6 Main Pool"
    }
  }
  schema_validation_enabled = false

  depends_on = [time_sleep.wait_30_seconds]
}

# Network Security Groups for subnet association
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

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "8080"
    direction                  = "Inbound"
    name                       = "AllowApp"
    priority                   = 1001
    protocol                   = "Tcp"
    source_address_prefix      = "10.0.0.0/16"
    source_port_range          = "*"
  }
}

resource "azurerm_network_security_group" "data" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.network_security_group.name}-data"
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "5432"
    direction                  = "Inbound"
    name                       = "AllowDatabase"
    priority                   = 1001
    protocol                   = "Tcp"
    source_address_prefix      = "10.0.0.0/16"
    source_port_range          = "*"
  }
}

# Route Table for demonstration
resource "azurerm_route_table" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.route_table.name
  resource_group_name = azurerm_resource_group.this.name

  route {
    address_prefix = "0.0.0.0/0"
    name           = "ToInternet"
    next_hop_type  = "Internet"
  }
}

# Comprehensive IPAM VNet with multiple subnet types
module "vnet_ipam_full" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  # DNS servers configuration
  # DNS servers configuration
  dns_servers = {
    dns_servers = toset(["1.1.1.1", "8.8.8.8"])
  }
  enable_telemetry = true
  # VNet gets address space from IPAM pool (IPv4 only for now)
  ipam_pools = [
    {
      id            = azapi_resource.ipam_pool_v4.id
      prefix_length = 20 # /20 provides ~4000 IPs for subnets
    }
  ]
  name = "${module.naming.virtual_network.name_unique}-ipam-full"
  subnets = {
    # IPAM-allocated subnets (created sequentially with delays)
    web = {
      name = "subnet-web-ipam"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool_v4.id
        prefix_length = 24 # /24 from the pool
      }]
      network_security_group = {
        id = azurerm_network_security_group.web.id
      }
      route_table = {
        id = azurerm_route_table.this.id
      }
      service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
    }

    app = {
      name = "subnet-app-ipam"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool_v4.id
        prefix_length = 24 # /24 from the pool (created after 30s delay)
      }]
      network_security_group = {
        id = azurerm_network_security_group.app.id
      }
      route_table = {
        id = azurerm_route_table.this.id
      }
      service_endpoints = ["Microsoft.Storage"]
    }

    data = {
      name = "subnet-data-ipam"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool_v4.id
        prefix_length = 25 # /25 from the pool (created after 60s delay)
      }]
      network_security_group = {
        id = azurerm_network_security_group.data.id
      }
      service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
    }

    # Mixed: Static subnet alongside IPAM subnets
    management = {
      name             = "subnet-management"
      address_prefixes = ["10.0.15.0/28"] # Small static management subnet
      network_security_group = {
        id = azurerm_network_security_group.app.id
      }
    }

    # IPv4 IPAM subnet (services)
    services = {
      name = "subnet-services"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool_v4.id
        prefix_length = 26 # /26 IPv4 (created after 90s delay)
      }]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }

    # Subnet with delegation
    containerinstances = {
      name = "subnet-aci"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool_v4.id
        prefix_length = 27 # /27 for container instances (created after 120s delay)
      }]
      delegations = [{
        name = "containerinstance_delegation"
        service_delegation = {
          name = "Microsoft.ContainerInstance/containerGroups"
        }
      }]
    }
  }
  tags = {
    Environment = "test"
    Purpose     = "ipam-comprehensive-testing"
    Scenario    = "full-ipam-deployment"
  }
}

terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
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

#Creating a Route Table with a unique name in the specified location.
resource "azurerm_route_table" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.route_table.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

# Creating a DDoS Protection Plan in the specified location.
resource "azurerm_network_ddos_protection_plan" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.network_ddos_protection_plan.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

#Creating a NAT Gateway in the specified location.
resource "azurerm_nat_gateway" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.nat_gateway.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

# Fetching the public IP address of the Terraform executor used for NSG
data "http" "public_ip" {
  method = "GET"
  url    = "http://api.ipify.org?format=json"
}

resource "azurerm_network_security_group" "https" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.network_security_group.name_unique
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "443"
    direction                  = "Inbound"
    name                       = "AllowInboundHTTPS"
    priority                   = 100
    protocol                   = "Tcp"
    source_address_prefix      = jsondecode(data.http.public_ip.response_body).ip
    source_port_range          = "*"
  }
}


#Defining the first virtual network (vnet-1) with its subnets and settings.
module "vnet1" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique

  address_space = ["192.168.0.0/16"]

  dns_servers = {
    dns_servers = ["8.8.8.8"]
  }

  ddos_protection_plan = {
    id = azurerm_network_ddos_protection_plan.this.id
    # due to resource cost
    enable = false
  }

  subnets = {
    subnet0 = {
      name             = "${module.naming.subnet.name_unique}0"
      address_prefixes = ["192.168.0.0/24"]
    }
    subnet1 = {
      name             = "${module.naming.subnet.name_unique}1"
      address_prefixes = ["192.168.1.0/24"]
      delegations = [{
        name = "Microsoft.Web.serverFarms"
        service_delegation = {
          name = "Microsoft.Web/serverFarms"
        }
      }]
      nat_gateway = {
        id = azurerm_nat_gateway.this.id
      }
      network_security_group = {
        id = azurerm_network_security_group.https.id
      }
      route_table = {
        id = azurerm_route_table.this.id
      }
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
  }
}

module "vnet2" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_network.name_unique}2"
  address_space       = ["10.0.0.0/27"]

  peerings = {
    "peertovnet1" = {
      name                         = module.naming.virtual_network_peering.name_unique
      remote_virtual_network_id    = module.vnet1.id
      allow_forwarded_traffic      = true
      allow_gateway_transit        = true
      allow_virtual_network_access = false
      use_remote_gateways          = false
    }
  }
}

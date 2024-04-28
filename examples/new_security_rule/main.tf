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

#Creating a Network Security Group with a rule allowing SSH access from the executor's IP address.
resource "azurerm_network_security_group" "ssh" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.network_security_group.name
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    direction                  = "Inbound"
    name                       = "test123"
    priority                   = 100
    protocol                   = "Tcp"
    source_address_prefix      = jsondecode(data.http.public_ip.response_body).ip
    source_port_range          = "*"
  }
}


locals {
  address_space = "10.0.0.0/16"
  subnets = {
    for i in range(3) :
    "subnet${i}" => {
      name             = "${module.naming.subnet.name_unique}${i}"
      address_prefixes = [cidrsubnet(local.address_space, 8, i)]
      network_security_group = {
        id = azurerm_network_security_group.ssh.id
      }
    }
  }
}

#Creating a virtual network with specified configurations, subnets, and associated Network Security Groups.
module "vnet" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
  subnets             = local.subnets
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
}

# Fetching the public IP address of the Terraform executor.
data "http" "public_ip" {
  method = "GET"
  url    = "http://api.ipify.org?format=json"
}

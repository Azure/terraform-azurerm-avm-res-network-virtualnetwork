terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
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

provider "azapi" {}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

# This is required for resource modules
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  location = local.selected_region
  name     = module.naming.resource_group.name_unique
}

#Creating a Network Security Group with a rule allowing SSH access from the executor's IP address.
resource "azapi_resource" "ssh" {
  location  = module.resource_group.location
  name      = module.naming.network_security_group.name
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/networkSecurityGroups@2024-07-01"
  body = {
    properties = {
      securityRules = [{
        name = "test123"
        properties = {
          access                   = "Allow"
          destinationAddressPrefix = "*"
          destinationPortRange     = "22"
          direction                = "Inbound"
          priority                 = 100
          protocol                 = "Tcp"
          sourceAddressPrefix      = jsondecode(data.http.public_ip.response_body).ip
          sourcePortRange          = "*"
        }
      }]
    }
  }
  response_export_values = []
}

locals {
  address_space = "10.0.0.0/16"
  subnets = {
    for i in range(3) :
    "subnet${i}" => {
      name             = "${module.naming.subnet.name_unique}${i}"
      address_prefixes = [cidrsubnet(local.address_space, 8, i)]
      network_security_group = {
        id = azapi_resource.ssh.id
      }
    }
  }
}

#Creating a virtual network with specified configurations, subnets, and associated Network Security Groups.
module "vnet" {
  source = "../../"

  location      = module.resource_group.location
  parent_id     = module.resource_group.resource_id
  address_space = ["10.0.0.0/16"]
  name          = module.naming.virtual_network.name_unique
  subnets       = local.subnets
}

# Fetching the public IP address of the Terraform executor.
data "http" "public_ip" {
  method = "GET"
  url    = "http://api.ipify.org?format=json"
}

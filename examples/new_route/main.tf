terraform {
  required_version = ">= 1.9, < 2.0"

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

resource "azapi_resource" "route_table" {
  location  = module.resource_group.location
  name      = "MyRouteTable"
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/routeTables@2024-07-01"
  body = {
    properties = {}
  }
  response_export_values = []
}

resource "azapi_resource" "route" {
  name      = "acceptanceTestRoute1"
  parent_id = azapi_resource.route_table.id
  type      = "Microsoft.Network/routeTables/routes@2024-07-01"
  body = {
    properties = {
      addressPrefix = local.address_space
      nextHopType   = "VnetLocal"
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
      route_table = {
        id = azapi_resource.route_table.id
      }
    }
  }
}

module "vnet" {
  source = "../../"

  location      = module.resource_group.location
  parent_id     = module.resource_group.resource_id
  address_space = ["10.0.0.0/16"]
  name          = module.naming.virtual_network.name
  subnets       = local.subnets
}

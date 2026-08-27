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

locals {
  address_space = "10.0.0.0/16"
  subnets = {
    for i in range(2) :
    "subnet${i}" => {
      name             = "${module.naming.subnet.name_unique}${i}"
      address_prefixes = [cidrsubnet(local.address_space, 8, i)]
    }
  }
}

resource "azapi_resource" "this" {
  location  = module.resource_group.location
  name      = module.naming.virtual_network.name_unique
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = [local.address_space]
      }
    }
  }
  response_export_values = []
}

module "subnets" {
  source   = "../../modules/subnet"
  for_each = local.subnets

  name             = each.value.name
  parent_id        = azapi_resource.this.id
  address_prefixes = each.value.address_prefixes
}

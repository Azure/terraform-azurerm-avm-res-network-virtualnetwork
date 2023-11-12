resource "random_id" "rg_name" {
  byte_length = 8
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# Creating a resource group with a unique name in the specified location.
resource "azurerm_resource_group" "example" {
  location = var.rg_location
  name     = module.naming.resource_group.name_unique
}

locals {
  subnets = {
    for i in range(3) : "subnet${i}" => {
      address_prefixes = [cidrsubnet(local.virtual_network_address_space, 8, i)]
    }
  }
  virtual_network_address_space = "10.0.0.0/16"
}

module "vnet" {
  source                        = "../../"
  resource_group_name           = azurerm_resource_group.example.name
  subnets                       = local.subnets
  virtual_network_address_space = [local.virtual_network_address_space]
  vnet_location                 = var.vnet_location
  vnet_name                     = "azure-subnets-vnet"
  new_network_ddos_protection_plan = {
    name = "ddos-protection-for-asv"
  }
}
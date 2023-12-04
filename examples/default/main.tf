# Importing the Azure naming module to ensure resources have unique CAF compliant names.
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

# Creating a virtual network with a unique name, telemetry settings, and in the specified resource group and location.
module "vnet" {
  source              = "../../"
  vnet_name           = module.naming.virtual_network.name
  enable_telemetry    = true
  resource_group_name = azurerm_resource_group.example.name
  vnet_location       = var.vnet_location
  subnets             = local.subnets


  virtual_network_dns_servers = {
    dns_servers = ["8.8.8.8"]
  }

  virtual_network_address_space = ["10.0.0.0/16"]

}




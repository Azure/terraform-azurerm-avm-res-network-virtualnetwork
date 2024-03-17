#Importing the Azure naming module to ensure resources have unique CAF compliant names.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

#Generating a random ID to be used for creating unique resource names.
resource "random_id" "rg_name" {
  byte_length = 8
}

#Creating a resource group with a unique name in the specified location.
resource "azurerm_resource_group" "example" {
  location = var.rg_location
  name     = module.naming.resource_group.name_unique
}

#Creating a Network Security Group with a unique name in the specified location.
resource "azurerm_network_security_group" "nsg1" {
  location            = var.vnet_location
  name                = "test-${random_id.rg_name.hex}-nsg"
  resource_group_name = azurerm_resource_group.example.name
}

#Creating a Route Table with a unique name in the specified location.
resource "azurerm_route_table" "rt1" {
  location            = var.vnet_location
  name                = "test-${random_id.rg_name.hex}-rt"
  resource_group_name = azurerm_resource_group.example.name
}

#Creating a DDoS Protection Plan in the specified location.
resource "azurerm_network_ddos_protection_plan" "example" {
  location            = var.vnet_location
  name                = "example-protection-plan"
  resource_group_name = azurerm_resource_group.example.name
}

#Creating a NAT Gateway in the specified location.
resource "azurerm_nat_gateway" "example" {
  location            = var.vnet_location
  name                = "example-natgateway"
  resource_group_name = azurerm_resource_group.example.name
}

#Defining the first virtual network (vnet-1) with its subnets and settings.
module "vnet_1" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.example.name

  subnets = {
    subnet0 = {
      address_prefixes = ["192.168.0.0/16"]
    }
  }

  virtual_network_address_space = ["192.168.0.0/16"]
  location                      = azurerm_resource_group.example.location
  name                          = "accttest-vnet-peer"


}
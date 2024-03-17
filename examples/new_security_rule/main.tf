#Importing the Azure naming module to ensure resources have unique CAF compliant names.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

#Creating a resource group with a unique name in the specified location.
resource "azurerm_resource_group" "example" {
  location = var.rg_location
  name     = module.naming.resource_group.name_unique
}

#Creating a Network Security Group with a rule allowing SSH access from the executor's IP address.
resource "azurerm_network_security_group" "ssh" {
  location            = azurerm_resource_group.example.location
  name                = module.naming.network_security_group.name
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    direction                  = "Inbound"
    name                       = "test123"
    priority                   = 100
    protocol                   = "Tcp"
    source_address_prefix      = jsondecode(data.curl.public_ip.response).ip
    source_port_range          = "*"
  }
}


locals {
  subnets = {
    for i in range(3) :
    "subnet${i}" => {
      address_prefixes = [cidrsubnet(local.virtual_network_address_space, 8, i)]
      network_security_group = {
        id = azurerm_network_security_group.ssh.id
      }
    }
  }
  virtual_network_address_space = "10.0.0.0/16"
}

#Creating a virtual network with specified configurations, subnets, and associated Network Security Groups.
module "vnet" {
  source                        = "../../"
  resource_group_name           = azurerm_resource_group.example.name
  virtual_network_address_space = ["10.0.0.0/16"]
  subnets                       = local.subnets
  location                      = azurerm_resource_group.example.location
  name                          = "azure_subnets_vnet"

}

#Fetching the public IP address of the Terraform executor.
data "curl" "public_ip" {
  http_method = "GET"
  uri         = "http://api.ipify.org?format=json"
}



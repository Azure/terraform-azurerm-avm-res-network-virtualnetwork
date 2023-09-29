// Importing the Azure naming module to ensure resources have unique CAF compliant names.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

// Creating a resource group with a unique name in the specified location.
resource "azurerm_resource_group" "example" {
  location = var.rg_location
  name     = module.naming.resource_group.name_unique
}

// Creating a virtual network with specified configurations, subnets, and associated Network Security Groups.
module "vnet" {
  source              = "../../"
  name                = module.naming.virtual_network.name
  enable_telemetry    = var.enable_telemetry
  resource_group_name = azurerm_resource_group.example.name
  vnet_location       = var.vnet_location
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names        = ["subnet1", "subnet2", "subnet3"]

  // Associating the same Network Security Group to all subnets.
  nsg_ids = {
    subnet1 = azurerm_network_security_group.ssh.id
    subnet2 = azurerm_network_security_group.ssh.id
    subnet3 = azurerm_network_security_group.ssh.id
  }

  // Applying tags to the virtual network.
  tags = {
    environment = "dev"
    costcenter  = "it"
  }
}

// Fetching the public IP address of the Terraform executor.
data "curl" "public_ip" {
  http_method = "GET"
  uri         = "https://api.ipify.org?format=json"
}

// Creating a Network Security Group with a rule allowing SSH access from the executor's IP address.
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

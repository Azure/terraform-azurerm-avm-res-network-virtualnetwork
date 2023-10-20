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


// Creating a Route Table in the same location and resource group.
resource "azurerm_route_table" "example" {
  location            = azurerm_resource_group.example.location
  name                = "MyRouteTable"
  resource_group_name = azurerm_resource_group.example.name
}

// Adding a route to the created Route Table.
resource "azurerm_route" "example" {
  address_prefix      = "10.1.0.0/16"
  name                = "acceptanceTestRoute1"
  next_hop_type       = "VnetLocal"
  resource_group_name = azurerm_resource_group.example.name
  route_table_name    = azurerm_route_table.example.name
}

// Creating a virtual network with specified configurations, subnets, and route tables.
module "vnet" {
  source              = "../../"
  name                = module.naming.virtual_network.name
  enable_telemetry    = var.enable_telemetry
  resource_group_name = azurerm_resource_group.example.name
  vnet_location       = var.vnet_location
  address_space       = "10.0.0.0/16"
  subnets = [
    {
      name           = "subnet1"
      address_prefix = "10.0.1.0/24"
      route_table_id = azurerm_route_table.example.id

    }
  ]

  // Applying tags to the virtual network.
  tags = {
    environment = "dev"
    costcenter  = "it"
  }
}
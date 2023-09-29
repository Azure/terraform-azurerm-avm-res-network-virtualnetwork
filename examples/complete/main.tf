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

// Creating a Network Security Group with a unique name in the specified resource group and location.
resource "azurerm_network_security_group" "nsg1" {
  location            = var.vnet_location
  name                = module.naming.network_security_group.name
  resource_group_name = azurerm_resource_group.example.name
}

// Creating a Route Table with a unique name in the specified resource group and location.
resource "azurerm_route_table" "rt1" {
  location            = var.vnet_location
  name                = module.naming.route_table.name
  resource_group_name = azurerm_resource_group.example.name
}

// Creating a virtual network with specified configurations, subnets, delegations, and network policies.
module "vnet" {
  source              = "../../"
  name                = module.naming.virtual_network.name
  enable_telemetry    = true
  resource_group_name = azurerm_resource_group.example.name
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names        = ["subnet1", "subnet2", "subnet3"]
  vnet_location       = var.vnet_location

  // Associating Network Security Group to subnet1.
  nsg_ids = {
    subnet1 = azurerm_network_security_group.nsg1.id
  }

  // Enabling specific service endpoints on subnet1 and subnet2.
  subnet_service_endpoints = {
    subnet1 = ["Microsoft.Storage"]
    subnet2 = ["Microsoft.Sql", "Microsoft.AzureActiveDirectory"]
  }

  // Configuring service delegation for subnet1 and subnet2.
  subnet_delegation = {
    subnet1 = [
      {
        name = "Microsoft.Web/serverFarms"
        service_delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    ]
    subnet2 = [
      {
        name = "Microsoft.Sql/managedInstances"
        service_delegation = {
          name    = "Microsoft.Sql/managedInstances"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    ]
  }

  // Associating Route Table to subnet1.
  route_tables_ids = {
    subnet1 = azurerm_route_table.rt1.id
  }

  // Applying tags to the virtual network.
  tags = {
    environment = "dev"
    costcenter  = "it"
  }

  // Enabling private link endpoint network policies on subnet2 and subnet3.
  private_link_endpoint_network_policies_enabled = {
    subnet2 = true
  }
  private_link_service_network_policies_enabled = {
    subnet3 = true
  }
}

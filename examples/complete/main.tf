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

//Creating a Network Security Group with a unique name in the specified resource group and location.
resource "azurerm_network_security_group" "nsg1" {
  location            = var.vnet_location
  name                = module.naming.network_security_group.name
  resource_group_name = azurerm_resource_group.example.name
}

//Creating a Route Table with a unique name in the specified resource group and location.
resource "azurerm_route_table" "rt1" {
  location            = var.vnet_location
  name                = module.naming.route_table.name
  resource_group_name = azurerm_resource_group.example.name
}

//Creating a virtual network with specified configurations, subnets, delegations, and network policies.
module "vnet" {
  source              = "../../"
  name                = module.naming.virtual_network.name
  enable_telemetry    = true
  resource_group_name = azurerm_resource_group.example.name
  address_space       = "10.0.0.0/16"
  vnet_location       = var.vnet_location
  dns_servers = [ "10.0.0.1", "10.0.0.2" ]

  subnets = [
    {
      name                                          = "subnet1"
      address_prefix                                = "10.0.1.0/24"
      nsg_id                                        = azurerm_network_security_group.nsg1.id
      route_table_id                                = azurerm_route_table.rt1.id
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
      service_endpoints                             = ["Microsoft.Sql", "Microsoft.AzureActiveDirectory"]
      delegation = [
        {
          name = "subnet_delgation1"
          service_delegation = {
            name    = "Microsoft.Web/serverFarms"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      ]
    },

    {
      name           = "subnet2"
      address_prefix = "10.0.2.0/24"
      nsg_id         = azurerm_network_security_group.nsg1.id
      route_table_id = azurerm_route_table.rt1.id

      service_endpoints = ["Microsoft.Storage"]
      delegation = [
        {
          name = "subnet_delgation1"
          service_delegation = {
            name    = "Microsoft.Sql/managedInstances"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      ]
    }

  ]

  tags = {
    environment = "dev"
    costcenter  = "it"
  }

  ddos_protection_plan = {
    enable = true
    id     = "/subscriptions/47d02a61-9001-41bd-b4e7-6be9289027f4/resourceGroups/nvm-monitoring-rg/providers/Microsoft.Network/ddosProtectionPlans/nvm-ddos-plan"
  }


}

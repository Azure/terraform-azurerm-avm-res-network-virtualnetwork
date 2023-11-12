// Importing the Azure naming module to ensure resources have unique CAF compliant names.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

resource "random_id" "rg_name" {
  byte_length = 8
}

// Creating a resource group with a unique name in the specified location.
resource "azurerm_resource_group" "example" {
  location = var.rg_location
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_network_security_group" "nsg1" {
  location            = var.vnet_location
  name                = "test-${random_id.rg_name.hex}-nsg"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_route_table" "rt1" {
  location            = var.vnet_location
  name                = "test-${random_id.rg_name.hex}-rt"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_network_ddos_protection_plan" "example" {
  location            = var.vnet_location
  name                = "example-protection-plan"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_nat_gateway" "example" {
  location            = var.vnet_location
  name                = "example-natgateway"
  resource_group_name = azurerm_resource_group.example.name
}

module "vnet-1" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.example.name

  subnets = {
    subnet0 = {
      address_prefixes = ["192.168.0.0/16"]

    }
  }

  virtual_network_address_space = ["192.168.0.0/16"]
  vnet_location                 = azurerm_resource_group.example.location
  vnet_name                     = "accttest-vnet-peer"

}

module "vnet-2" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.example.name

  subnets = {
    subnet0 = {
      address_prefixes                          = ["10.0.0.0/24"]
      private_endpoint_network_policies_enabled = false
      service_endpoints = [
        "Microsoft.Storage", "Microsoft.Sql"
      ]
      delegations = [
        {
          name = "Microsoft.Sql.managedInstances"
          service_delegation = {
            name = "Microsoft.Sql/managedInstances"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action",
              "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
              "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
            ]
          }
        }
      ]
    }
    subnet1 = {
      address_prefixes                          = ["10.0.1.0/24"]
      private_endpoint_network_policies_enabled = false
      service_endpoints                         = ["Microsoft.AzureActiveDirectory"]
    }
    subnet2 = {
      address_prefixes = ["10.0.2.0/24"]
      nat_gateway = {
        id = azurerm_nat_gateway.example.id
      }
      network_security_group = {
        id = azurerm_network_security_group.nsg1.id
      }
      route_table = {
        id = azurerm_route_table.rt1.id
      }
    }
  }
  virtual_network_dns_servers = {
    dns_servers = ["8.8.8.8"]
  }
  virtual_network_ddos_protection_plan = {
    id     = azurerm_network_ddos_protection_plan.example.id
    enable = true
  }
  //creates a 1 way vnet peering from vnet-2 to vnet-1
  vnet_peering_config = {
    peering1 = {
      remote_vnet_id          = module.vnet-1.vnet_id
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    }
  }

  virtual_network_address_space = ["10.0.0.0/16"]
  vnet_location                 = azurerm_resource_group.example.location
  vnet_name                     = "accttest-vnet"
}


resource "random_id" "rg_name" {
  byte_length = 8
}

resource "azurerm_resource_group" "example" {
  location = var.rg_location
  name     = "test-${random_id.rg_name.hex}-rg"
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

module "vnet" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.example.name
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names        = ["subnet1", "subnet2", "subnet3"]
  vnet_location       = var.vnet_location

  nsg_ids = {
    subnet1 = azurerm_network_security_group.nsg1.id
  }

  subnet_service_endpoints = {
    subnet1 = ["Microsoft.Storage"]
    subnet2 = ["Microsoft.Sql", "Microsoft.AzureActiveDirectory"]

  }
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


  route_tables_ids = {
    subnet1 = azurerm_route_table.rt1.id
  }

  tags = {
    environment = "dev"
    costcenter  = "it"
  }

  private_link_endpoint_network_policies_enabled = {
    subnet2 = true
  }

  private_link_service_network_policies_enabled = {
    subnet3 = true
  }

  ddos_protection_plan = {
    enable = true
    id     = "/subscriptions/47d02a61-9001-41bd-b4e7-6be9289027f4/resourceGroups/rg-techexp-uatmzna-tf/providers/Microsoft.Network/ddosProtectionPlans/test-ddos"
  }
}

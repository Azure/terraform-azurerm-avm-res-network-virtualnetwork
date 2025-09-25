terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.2"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Creating a virtual network with a unique name, telemetry settings, and in the specified resource group and location.
module "vnet" {
  source = "../../"

  address_space    = ["10.0.0.0/16"]
  location         = azurerm_resource_group.this.location
  enable_telemetry = true
  name             = module.naming.virtual_network.name
  parent_id        = azurerm_resource_group.this.id
  subnets = {
    test = {
      address_prefixes = ["10.0.0.0/16"]
      name             = "subnet0"
    }
  }
}

resource "azurerm_network_interface" "test" {
  location            = azurerm_resource_group.this.location
  name                = "nic-${module.naming.virtual_network.name}"
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipconfig0"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.vnet.subnets["test"].resource_id
  }
}

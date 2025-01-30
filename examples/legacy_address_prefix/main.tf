terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
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
  source  = "Azure/regions/azurerm"
  version = "~> 0.3"
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
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

module "vnet" {
  source              = "../../"
  name                = module.naming.virtual_network.name
  enable_telemetry    = true
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  address_space = ["10.0.0.0/16"]
  subnets = {
    subnet1 = {
      name                            = "subnet1"
      address_prefix                  = "10.0.0.0/24"
      default_outbound_access_enabled = true
      delegation = [{
        name = "aca_delegation"
        service_delegation = {
          name    = "Microsoft.App/environments"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }]
    }
  }
}

/* # NOTE: This resource take a long time to create and destroy, so we are removing from e2e tests.
resource "azurerm_container_app_environment" "aca" {
  name                       = module.naming.container_app_environment.name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name

  infrastructure_resource_group_name = "${module.naming.resource_group.name_unique}-aca"
  infrastructure_subnet_id           = module.vnet.subnets["subnet1"].resource_id
  internal_load_balancer_enabled = true

  workload_profile {
    name = "Consumption"
    workload_profile_type  = "Consumption"
    maximum_count = 1
    minimum_count = 0
  }
  zone_redundancy_enabled = false
}
*/

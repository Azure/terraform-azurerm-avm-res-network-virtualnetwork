terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
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

locals {
  random_tags = {
    (random_pet.tag[0].id) = random_pet.tag[1].id
    (random_pet.tag[2].id) = random_pet.tag[3].id
    (random_pet.tag[4].id) = random_pet.tag[5].id
    (random_pet.tag[6].id) = random_pet.tag[7].id
    (random_pet.tag[8].id) = random_pet.tag[9].id
  }
}

resource "time_rotating" "this" {
  rotation_minutes = 10
}

resource "random_pet" "tag" {
  count = 10

  keepers = {
    time_stamp = time_rotating.this.id
  }
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
  tags     = local.random_tags
}

# Creating a virtual network with a unique name, telemetry settings, and in the specified resource group and location.
module "vnet1" {
  source              = "../../"
  name                = "${module.naming.virtual_network.name}-01"
  enable_telemetry    = true
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tag_inheritance = {
    resource_group = true
  }

  address_space = ["10.0.0.0/16"]
}

module "vnet2" {
  source              = "../../"
  name                = "${module.naming.virtual_network.name}-02"
  enable_telemetry    = true
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tag_inheritance = {
    subscription = true
  }

  address_space = ["10.1.0.0/16"]
}

resource "terraform_data" "resource_group_name" {
  input = azurerm_resource_group.this.name
}

module "vnet_dynamic_resource_group_name" {
  source              = "../../"
  name                = "${module.naming.virtual_network.name}-03"
  enable_telemetry    = true
  resource_group_name = terraform_data.resource_group_name.output
  location            = azurerm_resource_group.this.location
  tag_inheritance = {
    resource_group = true
  }

  address_space = ["10.2.0.0/16"]
}

module "vnet_no_inheritance" {
  source              = "../../"
  name                = "${module.naming.virtual_network.name}-04"
  enable_telemetry    = true
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  address_space = ["10.3.0.0/16"]
}
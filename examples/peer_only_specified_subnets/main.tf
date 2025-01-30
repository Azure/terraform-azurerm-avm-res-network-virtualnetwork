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

#Defining the first virtual network (vnet-1) with its subnets and settings.
module "vnet1" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_network.name_unique}-1"

  address_space = ["10.0.0.0/16", "10.1.0.0/16"]

  subnets = {
    subnet1 = {
      name             = "${module.naming.subnet.name_unique}-1-1"
      address_prefixes = ["10.0.1.0/24", "10.0.2.0/24"]
    }
    subnet2 = {
      name             = "${module.naming.subnet.name_unique}-1-2"
      address_prefixes = ["10.0.3.0/24", "10.0.4.0/24"]
    }
    subnet3 = {
      name             = "${module.naming.subnet.name_unique}-1-3"
      address_prefixes = ["10.0.5.0/24", "10.0.6.0/24"]
    }
  }
}

module "vnet2" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_network.name_unique}-2"
  address_space       = ["10.2.0.0/16", "10.3.0.0/16"]

  subnets = {
    subnet1 = {
      name             = "${module.naming.subnet.name_unique}-2-1"
      address_prefixes = ["10.2.1.0/24", "10.2.2.0/24"]
    }
    subnet2 = {
      name             = "${module.naming.subnet.name_unique}-2-2"
      address_prefixes = ["10.2.3.0/24", "10.2.4.0/24"]
    }
    subnet3 = {
      name             = "${module.naming.subnet.name_unique}-2-3"
      address_prefixes = ["10.2.5.0/24", "10.2.6.0/24"]
    }
  }

  peerings = {
    peertovnet1 = {
      name                               = "${module.naming.virtual_network_peering.name_unique}-vnet2-to-vnet1"
      remote_virtual_network_resource_id = module.vnet1.resource_id
      allow_forwarded_traffic            = true
      allow_gateway_transit              = true
      allow_virtual_network_access       = true
      peer_complete_vnets                = false
      local_peered_subnets = [
        {
          subnet_name = "${module.naming.subnet.name_unique}-2-1"
        },
        {
          subnet_name = "${module.naming.subnet.name_unique}-2-2"
        }
      ]
      remote_peered_subnets = [
        {
          subnet_name = module.vnet1.subnets["subnet1"].name # NOTE: We are building an implicit dependency here as we need the peering to be destroyed prior to the subnet
        },
        {
          subnet_name = module.vnet1.subnets["subnet2"].name
        }
      ]

      create_reverse_peering               = true
      reverse_name                         = "${module.naming.virtual_network_peering.name_unique}-vnet1-to-vnet2"
      reverse_allow_forwarded_traffic      = false
      reverse_allow_gateway_transit        = false
      reverse_allow_virtual_network_access = true
      reverse_peer_complete_vnets          = false
      reverse_local_peered_subnets = [
        {
          subnet_name = module.vnet1.subnets["subnet1"].name
        },
        {
          subnet_name = module.vnet1.subnets["subnet2"].name
        }
      ]
      reverse_remote_peered_subnets = [
        {
          subnet_name = "${module.naming.subnet.name_unique}-2-1"
        },
        {
          subnet_name = "${module.naming.subnet.name_unique}-2-2"
        }
      ]
    }
  }
}

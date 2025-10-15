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

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = local.selected_region
  name     = module.naming.resource_group.name_unique
}

#Defining the first virtual network (vnet-1) with its subnets and settings.
module "vnet1" {
  source = "../../"

  location      = azurerm_resource_group.this.location
  parent_id     = azurerm_resource_group.this.id
  address_space = ["10.4.0.0/16", "10.5.0.0/16"]
  name          = "${module.naming.virtual_network.name_unique}-1"
  subnets = {
    subnet1 = {
      name             = "${module.naming.subnet.name_unique}-1-1"
      address_prefixes = ["10.4.1.0/24", "10.4.2.0/24"]
    }
    subnet2 = {
      name             = "${module.naming.subnet.name_unique}-1-2"
      address_prefixes = ["10.4.3.0/24", "10.4.4.0/24"]
    }
    subnet3 = {
      name             = "${module.naming.subnet.name_unique}-1-3"
      address_prefixes = ["10.5.5.0/24", "10.5.6.0/24"]
    }
  }
}

module "vnet2" {
  source = "../../"

  location      = azurerm_resource_group.this.location
  parent_id     = azurerm_resource_group.this.id
  address_space = ["10.6.0.0/16", "10.7.0.0/16"]
  name          = "${module.naming.virtual_network.name_unique}-2"
  peerings = {
    peertovnet1 = {
      name                               = "${module.naming.virtual_network_peering.name_unique}-vnet2-to-vnet1"
      remote_virtual_network_resource_id = module.vnet1.resource_id
      allow_forwarded_traffic            = true
      allow_gateway_transit              = true
      allow_virtual_network_access       = true
      peer_complete_vnets                = false
      local_peered_address_spaces = [
        {
          address_prefix = "10.6.1.0/24"
        },
        {
          address_prefix = "10.6.2.0/24"
        }
      ]
      remote_peered_address_spaces = [
        {
          address_prefix = "10.4.1.0/24"
        },
        {
          address_prefix = "10.4.2.0/24"
        }
      ]

      create_reverse_peering               = true
      reverse_name                         = "${module.naming.virtual_network_peering.name_unique}-vnet1-to-vnet2"
      reverse_allow_forwarded_traffic      = false
      reverse_allow_gateway_transit        = false
      reverse_allow_virtual_network_access = true
      reverse_peer_complete_vnets          = false
      reverse_local_peered_address_spaces = [
        {
          address_prefix = "10.4.1.0/24"
        },
        {
          address_prefix = "10.4.2.0/24"
        }
      ]
      reverse_remote_peered_address_spaces = [
        {
          address_prefix = "10.6.1.0/24"
        },
        {
          address_prefix = "10.6.2.0/24"
        }
      ]
    }
  }
  subnets = {
    subnet1 = {
      name             = "${module.naming.subnet.name_unique}-2-1"
      address_prefixes = ["10.6.1.0/24", "10.6.2.0/24"]
    }
    subnet2 = {
      name             = "${module.naming.subnet.name_unique}-2-2"
      address_prefixes = ["10.6.3.0/24", "10.6.4.0/24"]
    }
    subnet3 = {
      name             = "${module.naming.subnet.name_unique}-2-3"
      address_prefixes = ["10.7.5.0/24", "10.7.6.0/24"]
    }
  }
}

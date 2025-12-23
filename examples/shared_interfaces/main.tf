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

resource "azurerm_resource_group" "this" {
  location = local.selected_region
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

module "vnet" {
  source = "../../"

  location         = azurerm_resource_group.this.location
  parent_id        = azurerm_resource_group.this.id
  address_space    = ["10.10.0.0/16"]
  enable_telemetry = true
  name             = module.naming.virtual_network.name_unique

  # Shared interface: management lock (applies at virtual network scope)
  lock = {
    kind = "CanNotDelete"
  }

  # Shared interface: diagnostic settings (applies at virtual network scope)
  diagnostic_settings = {
    sendToLogAnalytics = {
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
    }
  }

  # Shared interface: role assignments (applies at virtual network scope)
  role_assignments = {
    vnetNetworkContributor = {
      principal_id               = azurerm_user_assigned_identity.this.principal_id
      role_definition_id_or_name = "Network Contributor"
    }
  }

  # Subnet creation + shared interface: role assignments at subnet scope
  subnets = {
    app = {
      name             = "${module.naming.subnet.name_unique}-app"
      address_prefixes = ["10.10.1.0/24"]

      role_assignments = {
        subnetReader = {
          principal_id               = azurerm_user_assigned_identity.this.principal_id
          role_definition_id_or_name = "Reader"
        }
      }
    }

    data = {
      name             = "${module.naming.subnet.name_unique}-data"
      address_prefixes = ["10.10.2.0/24"]
    }
  }
}

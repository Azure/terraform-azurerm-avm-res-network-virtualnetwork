data "azapi_client_config" "current" {}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.13.0"

  location               = var.location
  enable_telemetry       = false
  is_recommended         = true
  region_name_regex      = "euap$"
  region_name_regex_mode = "not_match"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  location               = local.selected_region
  name                   = "rg-avm-vnet-${random_string.suffix.result}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  body                   = {}
  response_export_values = []
}

resource "azapi_resource" "managed_remote" {
  location  = azapi_resource.resource_group.location
  name      = "vnet-managed-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.62.0.0/16"]
      }
    }
  }
  response_export_values = []
}

resource "azapi_resource" "external_remote" {
  location  = azapi_resource.resource_group.location
  name      = "vnet-external-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.63.0.0/16"]
      }
    }
  }
  response_export_values = []
}

module "vnet" {
  source = "../../../.."

  location         = azapi_resource.resource_group.location
  parent_id        = azapi_resource.resource_group.id
  address_space    = var.address_space
  enable_telemetry = false
  name             = "vnet-parent-${random_string.suffix.result}"
  peerings = {
    managed = {
      name                               = "managed"
      remote_virtual_network_resource_id = azapi_resource.managed_remote.id
    }
  }
  subnets = {
    managed = {
      name             = "managed"
      address_prefixes = ["10.60.1.0/24"]
    }
  }
}

resource "azapi_resource" "external_subnet" {
  name      = "external"
  parent_id = module.vnet.resource_id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-07-01"
  body = {
    properties = {
      addressPrefix = "10.60.2.0/24"
    }
  }
  locks                  = [module.vnet.resource_id]
  response_export_values = []
}

resource "azapi_resource" "external_peering" {
  name      = "external"
  parent_id = module.vnet.resource_id
  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01"
  body = {
    properties = {
      remoteVirtualNetwork = {
        id = azapi_resource.external_remote.id
      }
      allowVirtualNetworkAccess = true
    }
  }
  locks                  = [module.vnet.resource_id]
  response_export_values = []
}

data "azapi_resource" "live_vnet" {
  name      = "vnet-parent-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  response_export_values = [
    "properties.addressSpace.addressPrefixes",
    "properties.subnets",
    "properties.virtualNetworkPeerings",
  ]

  depends_on = [
    module.vnet,
    azapi_resource.external_subnet,
    azapi_resource.external_peering,
  ]
}

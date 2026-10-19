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
  location               = module.regions.regions[random_integer.region_index.result].name
  name                   = "rg-avm-import-${random_string.suffix.result}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  body                   = {}
  response_export_values = []
}

resource "azapi_resource" "remote_vnet" {
  location  = azapi_resource.resource_group.location
  name      = "vnet-remote-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.74.0.0/16"]
      }
    }
  }
  response_export_values = []
}

resource "azapi_resource" "existing_vnet" {
  location  = azapi_resource.resource_group.location
  name      = "vnet-import-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.70.0.0/16"]
      }
    }
  }
  response_export_values = []
}

resource "azapi_resource" "external_subnet" {
  name      = "external"
  parent_id = azapi_resource.existing_vnet.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-07-01"
  body = {
    properties = {
      addressPrefix = "10.70.1.0/24"
    }
  }
  locks                  = [azapi_resource.existing_vnet.id]
  response_export_values = []
}

resource "azapi_resource" "external_peering" {
  name      = "external"
  parent_id = azapi_resource.existing_vnet.id
  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01"
  body = {
    properties = {
      remoteVirtualNetwork = {
        id = azapi_resource.remote_vnet.id
      }
      allowVirtualNetworkAccess = true
    }
  }
  locks                  = [azapi_resource.existing_vnet.id]
  response_export_values = []
}

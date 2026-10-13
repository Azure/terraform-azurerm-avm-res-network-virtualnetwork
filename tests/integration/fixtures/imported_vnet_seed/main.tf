data "azapi_client_config" "current" {}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

  enable_telemetry       = false
  is_recommended         = true
  region_name_regex      = "euap$"
  region_name_regex_mode = "not_match"
}

resource "random_integer" "region_index" {
  min = 0
  max = length(module.regions.regions) - 1
}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2024-03-01"
  name      = "rg-avm-import-${random_string.suffix.result}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = module.regions.regions[random_integer.region_index.result].name
  body      = {}

  response_export_values = []
}

resource "azapi_resource" "remote_vnet" {
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  name      = "vnet-remote-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  location  = azapi_resource.resource_group.location
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
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  name      = "vnet-import-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  location  = azapi_resource.resource_group.location
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
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-07-01"
  name      = "external"
  parent_id = azapi_resource.existing_vnet.id
  locks     = [azapi_resource.existing_vnet.id]
  body = {
    properties = {
      addressPrefix = "10.70.1.0/24"
    }
  }

  response_export_values = []
}

resource "azapi_resource" "external_peering" {
  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01"
  name      = "external"
  parent_id = azapi_resource.existing_vnet.id
  locks     = [azapi_resource.existing_vnet.id]
  body = {
    properties = {
      remoteVirtualNetwork = {
        id = azapi_resource.remote_vnet.id
      }
      allowVirtualNetworkAccess = true
    }
  }

  response_export_values = []
}

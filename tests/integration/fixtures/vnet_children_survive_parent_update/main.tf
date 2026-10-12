data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2024-03-01"
  name      = "rg-avm-vnet-${random_string.suffix.result}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = "westeurope"
  body      = {}

  response_export_values = []
}

resource "azapi_resource" "managed_remote" {
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  name      = "vnet-managed-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  location  = azapi_resource.resource_group.location
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
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  name      = "vnet-external-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  location  = azapi_resource.resource_group.location
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

  name             = "vnet-parent-${random_string.suffix.result}"
  parent_id        = azapi_resource.resource_group.id
  location         = azapi_resource.resource_group.location
  address_space    = var.address_space
  enable_telemetry = false

  subnets = {
    managed = {
      name             = "managed"
      address_prefixes = ["10.60.1.0/24"]
    }
  }

  peerings = {
    managed = {
      name                               = "managed"
      remote_virtual_network_resource_id = azapi_resource.managed_remote.id
    }
  }
}

resource "azapi_resource" "external_subnet" {
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-07-01"
  name      = "external"
  parent_id = module.vnet.resource_id
  locks     = [module.vnet.resource_id]
  body = {
    properties = {
      addressPrefix = "10.60.2.0/24"
    }
  }

  response_export_values = []
}

resource "azapi_resource" "external_peering" {
  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01"
  name      = "external"
  parent_id = module.vnet.resource_id
  locks     = [module.vnet.resource_id]
  body = {
    properties = {
      remoteVirtualNetwork = {
        id = azapi_resource.external_remote.id
      }
      allowVirtualNetworkAccess = true
    }
  }

  response_export_values = []
}

data "azapi_resource" "live_vnet" {
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  name      = "vnet-parent-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
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

import {
  to = module.vnet.azapi_resource.vnet
  id = var.existing_vnet_id
}

module "vnet" {
  source = "../../../.."

  address_space    = ["10.70.0.0/15"]
  enable_telemetry = false
  location         = var.location
  name             = element(reverse(split("/", var.existing_vnet_id)), 0)
  parent_id        = var.parent_id
}

data "azapi_resource" "before_import" {
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  name      = element(reverse(split("/", var.existing_vnet_id)), 0)
  parent_id = var.parent_id
  response_export_values = [
    "properties.addressSpace.addressPrefixes",
    "properties.subnets",
    "properties.virtualNetworkPeerings",
  ]
}

data "azapi_resource" "live_vnet" {
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  name      = element(reverse(split("/", var.existing_vnet_id)), 0)
  parent_id = var.parent_id
  response_export_values = [
    "properties.addressSpace.addressPrefixes",
    "properties.subnets",
    "properties.virtualNetworkPeerings",
  ]

  depends_on = [module.vnet]
}

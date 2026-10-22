import {
  to = module.vnet.azapi_resource.vnet
  id = var.existing_vnet_id
}

module "vnet" {
  source = "../../../.."

  location         = var.location
  parent_id        = var.parent_id
  address_space    = ["10.70.0.0/15"]
  enable_telemetry = false
  name             = element(reverse(split("/", var.existing_vnet_id)), 0)
}

data "azapi_resource" "before_import" {
  name      = element(reverse(split("/", var.existing_vnet_id)), 0)
  parent_id = var.parent_id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  response_export_values = [
    "properties.addressSpace.addressPrefixes",
    "properties.subnets",
    "properties.virtualNetworkPeerings",
  ]
}

data "azapi_resource" "live_vnet" {
  name      = element(reverse(split("/", var.existing_vnet_id)), 0)
  parent_id = var.parent_id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  response_export_values = [
    "properties.addressSpace.addressPrefixes",
    "properties.subnets",
    "properties.virtualNetworkPeerings",
  ]

  depends_on = [module.vnet]
}

resource "azapi_resource" "vnet_peering" {
  for_each = var.existing_virtual_network == null ? var.peerings : {}

  type = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01"
  body = {
    properties = {
      remoteVirtualNetwork = {
        id = each.value.remote_virtual_network_resource_id
      }
      allowVirtualNetworkAccess = each.value.allow_virtual_network_access
      allowForwardedTraffic     = each.value.allow_forwarded_traffic
      allowGatewayTransit       = each.value.allow_gateway_transit
      useRemoteGateways         = each.value.use_remote_gateways
    }
  }
  locks                     = [azapi_resource.vnet[0].id]
  name                      = each.value.name
  parent_id                 = azapi_resource.vnet[0].id
  schema_validation_enabled = true

  depends_on = [
    azapi_resource.vnet,
    azapi_update_resource.vnet,
  ]
}

resource "azapi_resource" "reverse_vnet_peering" {
  for_each = var.existing_virtual_network == null ? { for k, v in var.peerings : k => v if v.create_reverse_peering } : {}

  type = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01"
  body = {
    properties = {
      remoteVirtualNetwork = {
        id = azapi_resource.vnet[0].id
      }
      allowVirtualNetworkAccess = each.value.reverse_allow_virtual_network_access
      allowForwardedTraffic     = each.value.reverse_allow_forwarded_traffic
      allowGatewayTransit       = each.value.reverse_allow_gateway_transit
      useRemoteGateways         = each.value.reverse_use_remote_gateways
    }
  }
  locks                     = [each.value.remote_virtual_network_resource_id]
  name                      = each.value.reverse_name
  parent_id                 = each.value.remote_virtual_network_resource_id
  schema_validation_enabled = true

  depends_on = [
    azapi_resource.vnet,
    azapi_update_resource.vnet,
  ]
}

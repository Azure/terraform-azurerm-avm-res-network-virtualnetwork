resource "azapi_resource" "this" {
  type = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01"
  body = {
    properties = {
      remoteVirtualNetwork = {
        id = var.remote_virtual_network.resource_id
      }
      allowVirtualNetworkAccess = var.allow_virtual_network_access
      allowForwardedTraffic     = var.allow_forwarded_traffic
      allowGatewayTransit       = var.allow_gateway_transit
      doNotVerifyRemoteGateways = var.do_not_verify_remote_gateways
      enableOnlyIPv6Peering     = var.enable_only_ipv6_peering
      peerCompleteVnets         = var.peer_complete_vnets

      useRemoteGateways = var.use_remote_gateways
    }
  }
  locks                     = [var.virtual_network.resource_id]
  name                      = var.name
  parent_id                 = var.virtual_network.resource_id
  schema_validation_enabled = true
}

resource "azapi_resource" "reverse" {
  count = var.create_reverse_peering ? 1 : 0

  type = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01"
  body = {
    properties = {
      remoteVirtualNetwork = {
        id = var.virtual_network.resource_id
      }
      allowVirtualNetworkAccess = var.reverse_allow_virtual_network_access
      allowForwardedTraffic     = var.reverse_allow_forwarded_traffic
      allowGatewayTransit       = var.reverse_allow_gateway_transit
      useRemoteGateways         = var.reverse_use_remote_gateways
      doNotVerifyRemoteGateways = var.reverse_do_not_verify_remote_gateways
      enableOnlyIPv6Peering     = var.reverse_enable_only_ipv6_peering
      peerCompleteVnets         = var.reverse_peer_complete_vnets
    }
  }
  locks                     = [var.remote_virtual_network.resource_id]
  name                      = var.reverse_name
  parent_id                 = var.remote_virtual_network.resource_id
  schema_validation_enabled = true

  depends_on = [azapi_update_resource.allow_multiple_peering_links_between_vnets]
}

resource "azapi_update_resource" "allow_multiple_peering_links_between_vnets" {
  count = !var.peer_complete_vnets || !var.reverse_peer_complete_vnets ? 1 : 0

  type = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = jsonencode({
    properties = {}
  })
  resource_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowMultiplePeeringLinksBetweenVnets"
}


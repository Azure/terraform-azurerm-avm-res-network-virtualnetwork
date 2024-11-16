# NOTE: We have multiple resource here for different use cases as it is currently the only method to support idempotency for the subnet peering scenario.
resource "azapi_resource" "this" {
  count = local.is_full_peering ? 1 : 0

  type = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01"
  body = {
    properties = {
      remoteVirtualNetwork = {
        id = var.remote_virtual_network.resource_id
      }
      allowVirtualNetworkAccess = var.allow_virtual_network_access
      allowForwardedTraffic     = var.allow_forwarded_traffic
      allowGatewayTransit       = var.allow_gateway_transit
      useRemoteGateways         = var.use_remote_gateways
      doNotVerifyRemoteGateways = var.do_not_verify_remote_gateways
      enableOnlyIPv6Peering     = var.enable_only_ipv6_peering
      peerCompleteVnets         = var.peer_complete_vnets
    }
  }
  locks                     = [var.virtual_network.resource_id]
  name                      = var.name
  parent_id                 = var.virtual_network.resource_id
  schema_validation_enabled = true
}

resource "azapi_resource" "reverse" {
  count = local.is_reverse_full_peering ? 1 : 0

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

  depends_on = [azapi_resource.this]
}

resource "azapi_resource" "address_space_peering" {
  count = local.is_address_space_peering ? 1 : 0

  type = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01"
  body = {
    properties = {
      remoteVirtualNetwork = {
        id = var.remote_virtual_network.resource_id
      }
      allowVirtualNetworkAccess = var.allow_virtual_network_access
      allowForwardedTraffic     = var.allow_forwarded_traffic
      allowGatewayTransit       = var.allow_gateway_transit
      useRemoteGateways         = var.use_remote_gateways
      doNotVerifyRemoteGateways = var.do_not_verify_remote_gateways
      enableOnlyIPv6Peering     = var.enable_only_ipv6_peering
      peerCompleteVnets         = var.peer_complete_vnets
      localAddressSpace = {
        addressPrefixes = [for address_prefix in var.local_peered_address_spaces : address_prefix.address_prefix]
      }
      remoteAddressSpace = {
        addressPrefixes = [for address_prefix in var.remote_peered_address_spaces : address_prefix.address_prefix]
      }
    }
  }
  locks                     = [var.virtual_network.resource_id]
  name                      = var.name
  parent_id                 = var.virtual_network.resource_id
  schema_validation_enabled = true

  depends_on = [
    azapi_update_resource.allow_multiple_peering_links_between_vnets,
    azapi_update_resource.remote_allow_multiple_peering_links_between_vnets
  ]
}

resource "azapi_resource" "reverse_address_space_peering" {
  count = local.is_reverse_address_space_peering ? 1 : 0

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
      localAddressSpace = {
        addressPrefixes = [for address_prefix in var.reverse_local_peered_address_spaces : address_prefix.address_prefix]
      }
      remoteAddressSpace = {
        addressPrefixes = [for address_prefix in var.reverse_remote_peered_address_spaces : address_prefix.address_prefix]
      }
    }
  }
  locks                     = [var.remote_virtual_network.resource_id]
  name                      = var.reverse_name
  parent_id                 = var.remote_virtual_network.resource_id
  schema_validation_enabled = true

  depends_on = [
    azapi_resource.address_space_peering,
    azapi_update_resource.allow_multiple_peering_links_between_vnets,
    azapi_update_resource.remote_allow_multiple_peering_links_between_vnets
  ]
}

resource "azapi_resource" "subnet_peering" {
  count = local.is_subnet_peering ? 1 : 0

  type = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01"
  body = {
    properties = {
      remoteVirtualNetwork = {
        id = var.remote_virtual_network.resource_id
      }
      allowVirtualNetworkAccess = var.allow_virtual_network_access
      allowForwardedTraffic     = var.allow_forwarded_traffic
      allowGatewayTransit       = var.allow_gateway_transit
      useRemoteGateways         = var.use_remote_gateways
      doNotVerifyRemoteGateways = var.do_not_verify_remote_gateways
      enableOnlyIPv6Peering     = var.enable_only_ipv6_peering
      peerCompleteVnets         = var.peer_complete_vnets
      localSubnetNames          = [for subnet in var.local_peered_subnets : subnet.subnet_name]
      remoteSubnetNames         = [for subnet in var.remote_peered_subnets : subnet.subnet_name]
    }
  }
  locks                     = [var.virtual_network.resource_id]
  name                      = var.name
  parent_id                 = var.virtual_network.resource_id
  schema_validation_enabled = true

  depends_on = [
    azapi_update_resource.allow_multiple_peering_links_between_vnets,
    azapi_update_resource.remote_allow_multiple_peering_links_between_vnets
  ]
}

resource "azapi_resource" "reverse_subnet_peering" {
  count = local.is_reverse_subnet_peering ? 1 : 0

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
      localSubnetNames          = [for subnet in var.reverse_local_peered_subnets : subnet.subnet_name]
      remoteSubnetNames         = [for subnet in var.reverse_remote_peered_subnets : subnet.subnet_name]
    }
  }
  locks                     = [var.remote_virtual_network.resource_id]
  name                      = var.reverse_name
  parent_id                 = var.remote_virtual_network.resource_id
  schema_validation_enabled = true

  depends_on = [
    azapi_resource.subnet_peering,
    azapi_update_resource.allow_multiple_peering_links_between_vnets,
    azapi_update_resource.remote_allow_multiple_peering_links_between_vnets
  ]
}

resource "azapi_update_resource" "allow_multiple_peering_links_between_vnets" {
  count = local.is_address_space_peering || local.is_subnet_peering ? 1 : 0

  type = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
  resource_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowMultiplePeeringLinksBetweenVnets"
}


resource "azapi_update_resource" "remote_allow_multiple_peering_links_between_vnets" {
  count = local.is_reverse_address_space_peering || local.is_reverse_subnet_peering ? 1 : 0

  type = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
  resource_id = "/subscriptions/${local.remote_subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowMultiplePeeringLinksBetweenVnets"
}

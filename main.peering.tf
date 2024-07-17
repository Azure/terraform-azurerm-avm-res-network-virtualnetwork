module "peering" {
  source   = "./modules/peering"
  for_each = var.peerings

  virtual_network                       = { resource_id = azapi_resource.vnet.id }
  remote_virtual_network                = { resource_id = each.value.remote_virtual_network_resource_id }
  name                                  = each.value.name
  allow_virtual_network_access          = each.value.allow_virtual_network_access
  allow_forwarded_traffic               = each.value.allow_forwarded_traffic
  allow_gateway_transit                 = each.value.allow_gateway_transit
  do_not_verify_remote_gateways         = each.value.do_not_verify_remote_gateways
  enable_only_ipv6_peering              = each.value.enable_only_ipv6_peering
  peer_complete_vnets                   = each.value.peer_complete_vnets
  use_remote_gateways                   = each.value.use_remote_gateways
  create_reverse_peering                = each.value.create_reverse_peering
  reverse_name                          = each.value.reverse_name
  reverse_allow_virtual_network_access  = each.value.reverse_allow_virtual_network_access
  reverse_allow_forwarded_traffic       = each.value.reverse_allow_forwarded_traffic
  reverse_allow_gateway_transit         = each.value.reverse_allow_gateway_transit
  reverse_do_not_verify_remote_gateways = each.value.reverse_do_not_verify_remote_gateways
  reverse_enable_only_ipv6_peering      = each.value.reverse_enable_only_ipv6_peering
  reverse_peer_complete_vnets           = each.value.reverse_peer_complete_vnets
  reverse_use_remote_gateways           = each.value.reverse_use_remote_gateways

  depends_on = [
    azapi_resource.vnet
  ]
}

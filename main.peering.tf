module "peering" {
  source   = "./modules/peering"
  for_each = var.peerings

  name                                  = each.value.name
  remote_virtual_network                = { resource_id = each.value.remote_virtual_network_resource_id }
  virtual_network                       = { resource_id = azapi_resource.vnet.id }
  allow_forwarded_traffic               = each.value.allow_forwarded_traffic
  allow_gateway_transit                 = each.value.allow_gateway_transit
  allow_virtual_network_access          = each.value.allow_virtual_network_access
  create_reverse_peering                = each.value.create_reverse_peering
  do_not_verify_remote_gateways         = each.value.do_not_verify_remote_gateways
  enable_only_ipv6_peering              = each.value.enable_only_ipv6_peering
  local_peered_address_spaces           = each.value.local_peered_address_spaces
  local_peered_subnets                  = each.value.local_peered_subnets
  peer_complete_vnets                   = each.value.peer_complete_vnets
  remote_peered_address_spaces          = each.value.remote_peered_address_spaces
  remote_peered_subnets                 = each.value.remote_peered_subnets
  retry                                 = each.value.retry
  reverse_allow_forwarded_traffic       = each.value.reverse_allow_forwarded_traffic
  reverse_allow_gateway_transit         = each.value.reverse_allow_gateway_transit
  reverse_allow_virtual_network_access  = each.value.reverse_allow_virtual_network_access
  reverse_do_not_verify_remote_gateways = each.value.reverse_do_not_verify_remote_gateways
  reverse_enable_only_ipv6_peering      = each.value.reverse_enable_only_ipv6_peering
  reverse_local_peered_address_spaces   = each.value.reverse_local_peered_address_spaces
  reverse_local_peered_subnets          = each.value.reverse_local_peered_subnets
  reverse_name                          = each.value.reverse_name
  reverse_peer_complete_vnets           = each.value.reverse_peer_complete_vnets
  reverse_remote_peered_address_spaces  = each.value.reverse_remote_peered_address_spaces
  reverse_remote_peered_subnets         = each.value.reverse_remote_peered_subnets
  reverse_use_remote_gateways           = each.value.reverse_use_remote_gateways
  subscription_id                       = local.subscription_id
  timeouts                              = each.value.timeouts
  use_remote_gateways                   = each.value.use_remote_gateways

  depends_on = [
    azapi_resource.vnet,
    module.subnet # NOTE: This to support subnet peering subnet must exist before peering is created and peering must be destroyed before subnet
  ]
}

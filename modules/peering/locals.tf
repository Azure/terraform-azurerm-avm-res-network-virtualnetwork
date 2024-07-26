locals {
  is_address_space_peering         = !var.peer_complete_vnets && length(var.local_peered_address_spaces == null ? [] : var.local_peered_address_spaces) > 0 && length(var.remote_peered_address_spaces == null ? [] : var.remote_peered_address_spaces) > 0
  is_full_peering                  = var.peer_complete_vnets
  is_reverse_address_space_peering = var.create_reverse_peering && !var.reverse_peer_complete_vnets && length(var.reverse_local_peered_address_spaces == null ? [] : var.reverse_local_peered_address_spaces) > 0 && length(var.reverse_remote_peered_address_spaces == null ? [] : var.reverse_remote_peered_address_spaces) > 0
  is_reverse_full_peering          = var.create_reverse_peering && var.reverse_peer_complete_vnets
  is_reverse_subnet_peering        = var.create_reverse_peering && !var.reverse_peer_complete_vnets && length(var.reverse_local_peered_subnets == null ? [] : var.reverse_local_peered_subnets) > 0 && length(var.reverse_remote_peered_subnets == null ? [] : var.reverse_remote_peered_subnets) > 0
  is_subnet_peering                = !var.peer_complete_vnets && length(var.local_peered_subnets == null ? [] : var.local_peered_subnets) > 0 && length(var.remote_peered_subnets == null ? [] : var.remote_peered_subnets) > 0
  output_resource_id               = local.is_full_peering ? azapi_resource.this[0].id : (local.is_address_space_peering ? azapi_resource.address_space_peering[0].id : azapi_resource.subnet_peering[0].id)
  output_resource_name             = local.is_full_peering ? azapi_resource.this[0].name : (local.is_address_space_peering ? azapi_resource.address_space_peering[0].name : azapi_resource.subnet_peering[0].name)
  output_reverse_resource_id       = var.create_reverse_peering ? (var.reverse_peer_complete_vnets ? azapi_resource.reverse[0].id : (local.is_reverse_address_space_peering ? azapi_resource.reverse_address_space_peering[0].id : azapi_resource.reverse_subnet_peering[0].id)) : null
  output_reverse_resource_name     = var.create_reverse_peering ? (var.reverse_peer_complete_vnets ? azapi_resource.reverse[0].name : (local.is_reverse_address_space_peering ? azapi_resource.reverse_address_space_peering[0].name : azapi_resource.reverse_subnet_peering[0].name)) : null
  remote_subscription_id           = var.create_reverse_peering ? split("/", var.remote_virtual_network.resource_id)[2] : ""
}

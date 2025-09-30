# Create time delays for IPAM subnet allocation to prevent conflicts
# This ensures sequential creation of IPAM subnets with proper delays
resource "time_sleep" "ipam_subnet_delay" {
  for_each = {
    for k, v in var.subnets : k => v
    if v.ipam_pools != null
  }

  create_duration = "${var.ipam_subnet_allocation_delay * (index(keys({
    for k, v in var.subnets : k => v
    if v.ipam_pools != null
  }), each.key) + 1)}s"
  triggers = {
    subnet_index = index(keys({
      for k, v in var.subnets : k => v
      if v.ipam_pools != null
    }), each.key)
    delay_config = var.ipam_subnet_allocation_delay
  }

  depends_on = [azapi_resource.vnet]
}

# Create ALL subnets (both IPAM and traditional) using the subnet module
# This ensures consistent architecture and feature parity
module "subnet" {
  source   = "./modules/subnet"
  for_each = var.subnets

  name      = each.value.name
  parent_id = azapi_resource.vnet.id
  # Traditional addressing - only set for non-IPAM subnets
  address_prefix = each.value.ipam_pools == null ? each.value.address_prefix : null
  address_prefixes = each.value.ipam_pools == null ? (
    each.value.calculate_from_vnet == true &&
    each.value.prefix_length != null &&
    local.vnet_address_space != null
    ? [cidrsubnet(
      local.vnet_address_space,
      each.value.prefix_length - tonumber(split("/", local.vnet_address_space)[1]),
      each.value.subnet_index != null ? each.value.subnet_index : 0
    )] : each.value.address_prefixes
  ) : null
  # All other subnet configuration (same for both IPAM and traditional)
  default_outbound_access_enabled = each.value.default_outbound_access_enabled
  delegations                     = each.value.delegations
  # IPAM configuration - only set for IPAM subnets
  ipam_pools                                    = each.value.ipam_pools
  nat_gateway                                   = each.value.nat_gateway
  network_security_group                        = each.value.network_security_group
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  retry                                         = each.value.retry
  role_assignments                              = each.value.role_assignments
  route_table                                   = each.value.route_table
  service_endpoint_policies                     = each.value.service_endpoint_policies
  service_endpoints                             = each.value.service_endpoints
  service_endpoints_with_location               = each.value.service_endpoints_with_location
  sharing_scope                                 = each.value.sharing_scope
  timeouts                                      = each.value.timeouts

  # Ensure IPAM subnets wait for their delay before creation
  depends_on = [
    time_sleep.ipam_subnet_delay
  ]
}

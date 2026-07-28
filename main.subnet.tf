# Create subnets using the subnet module
module "subnet" {
  source   = "./modules/subnet"
  for_each = var.subnets

  name                                          = each.value.name
  parent_id                                     = azapi_resource.vnet.id
  address_prefix                                = each.value.address_prefix
  address_prefixes                              = each.value.address_prefixes
  default_outbound_access_enabled               = each.value.default_outbound_access_enabled
  delegations                                   = each.value.delegations
  ipam_pools                                    = each.value.ipam_pools
  nat_gateway                                   = each.value.nat_gateway
  network_security_group                        = each.value.network_security_group
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  retry                                         = each.value.retry
  role_assignments                              = each.value.role_assignments
  route_table                                   = each.value.route_table
  service_endpoint_policies                     = each.value.service_endpoint_policies
  service_endpoints                             = local.subnet_service_endpoints[each.key]
  sharing_scope                                 = each.value.sharing_scope
  timeouts                                      = each.value.timeouts
}

# Warn, rather than fail, when a consumer is still using the deprecated
# `service_endpoints_with_location` attribute. The value is still honoured (the
# service names are mapped through, the locations are discarded), so upgrading
# does not break existing configurations.
check "subnet_service_endpoints_with_location_deprecated" {
  assert {
    condition     = length(local.subnets_using_service_endpoints_with_location) == 0
    error_message = "`service_endpoints_with_location` is deprecated and will be removed in a future release. Use `service_endpoints` with a set of service names instead, for example `service_endpoints = [\"Microsoft.Storage\"]`. The service names configured here are still applied, but the locations are ignored because Azure expands service-endpoint locations implicitly, which caused perpetual drift. Affected subnets: ${join(", ", local.subnets_using_service_endpoints_with_location)}."
  }
}

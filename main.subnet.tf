module "subnet" {
  source   = "./modules/subnet"
  for_each = var.subnets

  name                                          = each.value.name
  virtual_network                               = { resource_id = azapi_resource.vnet.id }
  address_prefix                                = each.value.address_prefix
  address_prefixes                              = each.value.address_prefixes
  default_outbound_access_enabled               = each.value.default_outbound_access_enabled
  delegation                                    = each.value.delegation
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
  sharing_scope                                 = each.value.sharing_scope
  subscription_id                               = local.subscription_id
  timeouts                                      = each.value.timeouts

  depends_on = [
    azapi_resource.vnet
  ]
}

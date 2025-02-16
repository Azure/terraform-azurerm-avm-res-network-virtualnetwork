module "subnet" {
  # tflint-ignore: required_module_source_tffr1
  source = "./modules/subnet"

  for_each = var.subnets

  virtual_network                               = { resource_id = azapi_resource.vnet.id }
  name                                          = each.value.name
  address_prefix                                = each.value.address_prefix
  address_prefixes                              = each.value.address_prefixes
  delegation                                    = each.value.delegation
  default_outbound_access_enabled               = each.value.default_outbound_access_enabled
  sharing_scope                                 = each.value.sharing_scope
  nat_gateway                                   = each.value.nat_gateway
  network_security_group                        = each.value.network_security_group
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  route_table                                   = each.value.route_table
  service_endpoints                             = each.value.service_endpoints
  service_endpoint_policies                     = each.value.service_endpoint_policies
  role_assignments                              = each.value.role_assignments
  subscription_id                               = local.subscription_id

  depends_on = [
    azapi_resource.vnet
  ]
}

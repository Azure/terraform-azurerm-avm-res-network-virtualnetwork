module "subnet" {
  source = "./modules/subnet"

  for_each = var.subnets

  subscription_id      = var.subscription_id
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.name

  name                                          = each.value.name
  address_prefixes                              = each.value.address_prefixes
  delegation                                    = each.value.delegation
  nat_gateway                                   = each.value.nat_gateway
  network_security_group                        = each.value.network_security_group
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  route_table                                   = each.value.route_table
  service_endpoints                             = each.value.service_endpoints
  role_assignments                              = each.value.role_assignments

  depends_on = [
    azapi_resource.vnet,
    azapi_update_resource.vnet,
  ]
}

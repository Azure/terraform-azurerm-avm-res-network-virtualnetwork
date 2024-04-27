resource "azapi_resource" "subnet" {
  for_each = var.subnets

  type      = "Microsoft.Network/virtualNetworks/subnets@2023-04-01"
  name      = each.value.name
  parent_id = "/subscriptions/${data.azurerm_subscription.this.id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}"

  body = {
    properties = {
      addressPrefixes = each.value.address_prefixes
      delegations     = each.value.delegations == null ? [] : each.value.delegations
      natGateway = {
        id = each.value.nat_gateway == null ? null : each.value.nat_gateway.id
      }
      networkSecurityGroup              = each.value.network_security_group == null ? null : each.value.network_security_group.id
      privateEndpointNetworkPolicies    = each.value.private_endpoint_network_policies_enabled
      privateLinkServiceNetworkPolicies = each.value.private_link_service_network_policies_enabled
      routeTable                        = each.value.network_security_group == null ? null : each.value.network_security_group.id
      serviceEndpoints                  = each.value.service_endpoints == null ? [] : each.value.service_endpoints
    }
  }
}

#Required AVM Shared interfaces 
resource "azurerm_role_assignment" "subnet_level" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.subnet[each.key].id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

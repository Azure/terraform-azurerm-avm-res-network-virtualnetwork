resource "azapi_resource" "subnet" {
  for_each = var.subnets

  type      = "Microsoft.Network/virtualNetworks/subnets@2023-04-01"
  name      = each.value.name
  parent_id = "${data.azurerm_subscription.this.id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}"

  body = {
    properties = {
      addressPrefixes = each.value.address_prefixes
      delegations = each.value.delegations != null ? [
        for delegation in each.value.delegations : {
          name = delegation.name
          properties = {
            serviceName = delegation.service_delegation.name
          }
        }
      ] : []
      natGateway = each.value.nat_gateway != null ? {
        id = each.value.nat_gateway.id
      } : null
      networkSecurityGroup = each.value.network_security_group != null ? {
        id = each.value.network_security_group.id
      } : null
      privateEndpointNetworkPolicies    = each.value.private_endpoint_network_policies_enabled == false ? "Disabled" : "Enabled"
      privateLinkServiceNetworkPolicies = each.value.private_link_service_network_policies_enabled == false ? "Disabled" : "Enabled"
      routeTable = each.value.route_table != null ? {
        id = each.value.route_table.id
      } : null
      serviceEndpoints = each.value.service_endpoints != null ? [
        for service_endpoint in each.value.service_endpoints : {
          service = service_endpoint
        }
      ] : null
    }
  }
  tags = var.tags

  depends_on = [
    azapi_resource.vnet,
    azapi_update_resource.vnet,
    time_sleep.wait_for_vnet_before_subnet_operations,
  ]
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

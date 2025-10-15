resource "azapi_resource" "subnet" {
  count = local.ipam_enabled ? 0 : 1

  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-07-01"
  body = {
    properties = {
      addressPrefix         = var.ipam_pools == null ? var.address_prefix : null
      addressPrefixes       = var.ipam_pools == null ? var.address_prefixes : null
      delegations           = local.delegations
      defaultOutboundAccess = var.default_outbound_access_enabled
      natGateway = var.nat_gateway != null ? {
        id = var.nat_gateway.id
      } : null
      networkSecurityGroup = var.network_security_group != null ? {
        id = var.network_security_group.id
      } : null
      privateEndpointNetworkPolicies    = var.private_endpoint_network_policies
      privateLinkServiceNetworkPolicies = var.private_link_service_network_policies_enabled == false ? "Disabled" : "Enabled"
      routeTable = var.route_table != null ? {
        id = var.route_table.id
      } : null
      serviceEndpoints = var.service_endpoints_with_location != null ? [
        for service_endpoint in var.service_endpoints_with_location : {
          service   = service_endpoint.service
          locations = service_endpoint.locations
        }
      ] : null
      serviceEndpointPolicies = var.service_endpoint_policies != null ? [
        for service_endpoint_policy in var.service_endpoint_policies : {
          id = service_endpoint_policy.id
        }
      ] : null
      sharingScope = var.sharing_scope
    }
  }
  locks                     = [var.parent_id]
  response_export_values    = ["properties.addressPrefixes", "properties.addressPrefix"]
  retry                     = var.retry
  schema_validation_enabled = true

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }
}

moved {
  from = azapi_resource.subnet
  to   = azapi_resource.subnet[0]
}

resource "azurerm_role_assignment" "subnet" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = local.ipam_enabled ? azapi_resource.subnet_ipam[0].id : azapi_resource.subnet[0].id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

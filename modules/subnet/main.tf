locals {
  # Define address options for the subnet - use calculated or provided addresses
  address_options = {
    addressPrefixes = {
      addressPrefixes = local.final_address_prefixes
    }
  }
}

resource "azapi_resource" "subnet" {
  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-07-01"
  body = {
    properties = merge(
      local.address_options["addressPrefixes"],
      {
        addressPrefix         = local.final_address_prefix
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
        serviceEndpoints = local.service_endpoints_to_use != null ? [
          for service_endpoint in local.service_endpoints_to_use : {
            service   = service_endpoint.service
            locations = can(service_endpoint.locations) ? service_endpoint.locations : null
          }
        ] : null
        serviceEndpointPolicies = var.service_endpoint_policies != null ? [
          for service_endpoint_policy in var.service_endpoint_policies : {
            id = service_endpoint_policy.id
          }
        ] : null
        sharingScope = var.sharing_scope
      }
    )
  }
  ignore_null_property = true
  locks                = [var.parent_id]
  # We do not use outputs, so disabling them
  response_export_values    = []
  retry                     = var.retry
  schema_validation_enabled = true

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }
}

resource "azurerm_role_assignment" "subnet" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.subnet.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

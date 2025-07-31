resource "azapi_resource" "subnet" {
  name      = var.name
  parent_id = var.virtual_network.resource_id
  type      = "Microsoft.Network/virtualNetworks/subnets@2023-11-01"
  body = {
    properties = {
      addressPrefix         = var.address_prefix
      addressPrefixes       = var.address_prefixes
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
  locks                     = [var.virtual_network.resource_id]
  retry                     = var.retry
  schema_validation_enabled = true

  # We do not use outputs, so disabling them
  response_export_values = []

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }

  depends_on = [
    azapi_update_resource.allow_multiple_address_prefixes_on_subnet,
    azapi_update_resource.allow_deletion_of_ip_prefix_from_subnet,
    azapi_update_resource.enable_shared_vnet
  ]
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

resource "azapi_update_resource" "allow_multiple_address_prefixes_on_subnet" {
  count = local.has_multiple_address_prefixes ? 1 : 0

  resource_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowMultipleAddressPrefixesOnSubnet"
  type        = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
}

resource "azapi_update_resource" "allow_deletion_of_ip_prefix_from_subnet" {
  count = local.has_multiple_address_prefixes ? 1 : 0

  resource_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowDeletionOfIpPrefixFromSubnet"
  type        = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
}

resource "azapi_update_resource" "enable_shared_vnet" {
  count = var.sharing_scope == "Tenant" ? 1 : 0

  resource_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/EnableSharedVNet"
  type        = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
}

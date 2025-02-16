resource "azapi_resource" "subnet" {
  type = "Microsoft.Network/virtualNetworks/subnets@2023-11-01"
  body = {
    properties = {
      addressPrefix   = var.address_prefix
      addressPrefixes = var.address_prefixes
      delegations = var.delegation != null ? [
        for delegation in var.delegation : {
          name = delegation.name
          properties = {
            serviceName = delegation.service_delegation.name
          }
        }
      ] : []
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
      serviceEndpoints = var.service_endpoints != null ? [
        for service_endpoint in var.service_endpoints : {
          service = service_endpoint
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
  name                      = var.name
  parent_id                 = var.virtual_network.resource_id
  schema_validation_enabled = true

  depends_on = [
    azapi_update_resource.allow_multiple_address_prefixes_on_subnet,
    azapi_update_resource.allow_deletion_of_ip_prefix_from_subnet,
    azapi_update_resource.enable_shared_vnet
  ]

  lifecycle {
    ignore_changes = [
      body.properties.ipConfigurations,
      body.properties.privateEndpoints
    ]
  }
}

data "azapi_resource_list" "role_definition" {
  for_each = local.role_assignments_by_name

  parent_id = azapi_resource.subnet.id
  type      = "Microsoft.Authorization/roleDefinitions@2022-05-01-preview"
  query_parameters = {
    "$filter" = ["roleName eq '${each.value.role_definition_id_or_name}'"]
  }
  response_export_values = {
    "values" = "value[].{id: id}"
  }
}
# a random uuid resource is used so the id is recorded in state, if just using uuid() the id would be different each time
resource "random_uuid" "role_assignment" {
  for_each = var.role_assignments
}

resource "azapi_resource" "role_assignment" {
  for_each = var.role_assignments

  type = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId                        = each.value.principal_id
      roleDefinitionId                   = local.role_definition_id_map[each.key]
      condition                          = each.value.condition
      conditionVersion                   = each.value.condition_version
      delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
      description                        = each.value.description
    }
  }
  name                   = random_uuid.role_assignment[each.key].result
  parent_id              = azapi_resource.subnet.id
  response_export_values = []

  depends_on = [
    azapi_resource.subnet
  ]

  lifecycle {
    ignore_changes = [
      name,
    ]
  }
}

resource "azapi_update_resource" "allow_multiple_address_prefixes_on_subnet" {
  count = local.has_multiple_address_prefixes ? 1 : 0

  type = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
  resource_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowMultipleAddressPrefixesOnSubnet"
}

resource "azapi_update_resource" "allow_deletion_of_ip_prefix_from_subnet" {
  count = local.has_multiple_address_prefixes ? 1 : 0

  type = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
  resource_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowDeletionOfIpPrefixFromSubnet"
}

resource "azapi_update_resource" "enable_shared_vnet" {
  count = var.sharing_scope == "Tenant" ? 1 : 0

  type = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
  resource_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/EnableSharedVNet"
}

moved {
  from = azurerm_role_assignment.subnet
  to   = azapi_resource.role_assignment
}

# Create IPAM-managed subnet when IPAM pools are specified
resource "azapi_resource" "ipam_subnet" {
  count = var.ipam_pools != null ? 1 : 0

  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-07-01"
  body = {
    properties = merge(
      {
        ipamPoolPrefixAllocations = [
          for pool in var.ipam_pools : {
            pool = {
              id = pool.pool_id
            }
            numberOfIpAddresses = tostring(
              pool.prefix_length <= 32
              ? pow(2, 32 - pool.prefix_length) # IPv4 calculation
              : 0                               # IPv6 - Azure uses 0 for IPv6 pools
            )
          }
        ]
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
  ignore_null_property   = false
  locks                  = [var.parent_id]
  response_export_values = ["properties.addressPrefixes"]
  retry = {
    error_message_regex = [
      "AnotherOperationInProgress",
      "ReferencedResourceNotProvisioned",
      "OperationNotAllowed"
    ]
    interval_seconds     = 30
    max_interval_seconds = 300
    multiplier           = 1.5
    randomization_factor = 0.5
  }
  schema_validation_enabled = false

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }
}

# Create traditional subnet when explicit addressing is used
resource "azapi_resource" "subnet" {
  count = var.ipam_pools == null ? 1 : 0

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
  scope                                  = var.ipam_pools != null ? azapi_resource.ipam_subnet[0].id : azapi_resource.subnet[0].id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

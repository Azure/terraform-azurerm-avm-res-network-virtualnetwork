locals {
  # When IPAM is used, after the prefix has been allocated, it is populated to addressPrefixes.
  # The next time TF is planned it will try to assert addressPrefixes back to null
  # ignore_changes is not dynamic and cannot be used to ignore changes to the addressPrefixes property based on the presence of IPAM.
  # To avoid this, we need to check if the IPAM pool is requested and define which values to use based on the presence of the IPAM variable.
  # If the IPAM pool is not provided, use the addressPrefixes.
  # If the IPAM pool is provided, use the ipamPoolPrefixAllocations
  address_options = {
    addressPrefixes = {
      addressPrefixes = var.address_prefixes
    }
    ipamPoolPrefixAllocations = {
      ipamPoolPrefixAllocations = var.ipam_pools != null ? [
        for ipam_pool in var.ipam_pools : {
          numberOfIpAddresses = tostring(pow(2, (ipam_pool.prefix_length == 64 ? 128 : 32) - ipam_pool.prefix_length))
          pool = {
            id = ipam_pool.id
          }
      }] : []
    }
  }
}

resource "azapi_resource" "subnet" {
  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-07-01"
  body = {
    properties = merge(
      local.address_options[var.ipam_pools != null ? "ipamPoolPrefixAllocations" : "addressPrefixes"],
      {
        addressPrefix         = var.address_prefix
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

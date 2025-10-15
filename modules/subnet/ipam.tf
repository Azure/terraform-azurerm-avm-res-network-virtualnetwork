resource "azapi_resource" "subnet_ipam" {
  count = local.ipam_enabled ? 1 : 0

  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-07-01"
  body = {
    properties = {
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
  response_export_values    = ["properties.addressPrefixes"]
  retry                     = var.retry
  schema_validation_enabled = true

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }
}

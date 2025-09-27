# Create time delays for IPAM subnet allocation to prevent conflicts
# This ensures sequential creation of IPAM subnets with proper delays
resource "time_sleep" "ipam_subnet_delay" {
  for_each = {
    for k, v in var.subnets : k => v
    if v.ipam_pools != null
  }

  create_duration = "${var.ipam_subnet_allocation_delay * (index(keys({
    for k, v in var.subnets : k => v
    if v.ipam_pools != null
  }), each.key) + 1)}s"
  triggers = {
    subnet_index = index(keys({
      for k, v in var.subnets : k => v
      if v.ipam_pools != null
    }), each.key)
    delay_config = var.ipam_subnet_allocation_delay
  }

  depends_on = [azapi_resource.vnet]
}

# Create IPAM-managed subnets with time delays and retry logic
resource "azapi_resource" "ipam_subnet" {
  for_each = {
    for k, v in var.subnets : k => v
    if v.ipam_pools != null
  }

  name      = each.value.name
  parent_id = azapi_resource.vnet.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-07-01"
  body = {
    properties = merge(
      {
        ipamPoolPrefixAllocations = [
          for pool in each.value.ipam_pools : {
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
        delegations = each.value.delegations != null ? [
          for delegation in each.value.delegations : {
            name = delegation.name
            properties = {
              serviceName = delegation.service_delegation.name
            }
          }
        ] : []
        defaultOutboundAccess = each.value.default_outbound_access_enabled != null ? each.value.default_outbound_access_enabled : false
        natGateway = each.value.nat_gateway != null ? {
          id = each.value.nat_gateway.id
        } : null
        networkSecurityGroup = each.value.network_security_group != null ? {
          id = each.value.network_security_group.id
        } : null
        privateEndpointNetworkPolicies    = each.value.private_endpoint_network_policies != null ? each.value.private_endpoint_network_policies : "Enabled"
        privateLinkServiceNetworkPolicies = each.value.private_link_service_network_policies_enabled == false ? "Disabled" : "Enabled"
        routeTable = each.value.route_table != null ? {
          id = each.value.route_table.id
        } : null
        serviceEndpoints = each.value.service_endpoints != null ? [
          for service_endpoint in each.value.service_endpoints : {
            service = service_endpoint
          }
          ] : each.value.service_endpoints_with_location != null ? [
          for service_endpoint in each.value.service_endpoints_with_location : {
            service   = service_endpoint.service
            locations = can(service_endpoint.locations) ? service_endpoint.locations : null
          }
        ] : null
        serviceEndpointPolicies = each.value.service_endpoint_policies != null ? [
          for service_endpoint_policy in each.value.service_endpoint_policies : {
            id = service_endpoint_policy.id
          }
        ] : null
        sharingScope = each.value.sharing_scope
      }
    )
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_null_property   = false
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
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
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = "30m"
    delete = "30m"
    read   = "5m"
    update = "30m"
  }

  depends_on = [time_sleep.ipam_subnet_delay]
}

# Create traditional subnets (non-IPAM) using the subnet module
module "subnet" {
  source   = "./modules/subnet"
  for_each = local.calculated_subnets

  name                                          = each.value.name
  parent_id                                     = azapi_resource.vnet.id
  address_prefix                                = each.value.final_address_prefix
  address_prefixes                              = each.value.final_address_prefixes
  default_outbound_access_enabled               = each.value.default_outbound_access_enabled
  delegations                                   = each.value.delegations
  nat_gateway                                   = each.value.nat_gateway
  network_security_group                        = each.value.network_security_group
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  retry                                         = each.value.retry
  role_assignments                              = each.value.role_assignments
  route_table                                   = each.value.route_table
  service_endpoint_policies                     = each.value.service_endpoint_policies
  service_endpoints                             = each.value.service_endpoints
  service_endpoints_with_location               = each.value.service_endpoints_with_location
  sharing_scope                                 = each.value.sharing_scope
  timeouts                                      = each.value.timeouts
}

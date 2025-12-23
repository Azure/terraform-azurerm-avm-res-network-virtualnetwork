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

module "avm_interfaces" {
  source = "git::https://github.com/Azure/terraform-azure-avm-utl-interfaces.git?ref=feat/prepv1"
  #version = "0.4.0"

  # Required by the interfaces module (used for some extension resources).
  parent_id        = var.parent_id
  this_resource_id = local.ipam_enabled ? azapi_resource.subnet_ipam[0].id : azapi_resource.subnet[0].id
  enable_telemetry = var.enable_telemetry

  role_assignments = var.role_assignments
}

moved {
  from = azurerm_role_assignment.subnet
  to   = module.avm_interfaces.azapi_resource.role_assignments
}

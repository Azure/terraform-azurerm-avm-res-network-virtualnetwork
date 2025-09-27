locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

locals {
  # Calculate the final address prefix - prioritizing address_prefix over address_prefixes
  final_address_prefix   = var.address_prefix
  final_address_prefixes = var.address_prefixes
}

locals {
  # Determine which service endpoints to use, preferring service_endpoints_with_location
  service_endpoints_to_use = var.service_endpoints_with_location != null ? [
    for endpoint in var.service_endpoints_with_location : {
      service   = endpoint.service
      locations = endpoint.locations
    }
    ] : var.service_endpoints != null ? [
    for endpoint_string in var.service_endpoints : {
      service = endpoint_string
    }
  ] : null
}

locals {
  delegations = var.delegations != null ? [
    for delegation in var.delegations : {
      name = delegation.name
      properties = {
        serviceName = delegation.service_delegation.name
      }
    }
  ] : local.delegations_legacy
  delegations_legacy = var.delegation != null ? [
    for delegation in var.delegation : {
      name = delegation.name
      properties = {
        serviceName = delegation.service_delegation.name
      }
    }
  ] : []
}

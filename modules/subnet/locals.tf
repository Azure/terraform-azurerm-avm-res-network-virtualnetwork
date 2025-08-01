locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

locals {
  has_multiple_address_prefixes = var.address_prefixes != null ? length(var.address_prefixes) > 1 : false
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

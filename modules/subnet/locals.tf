locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

locals {
  has_multiple_address_prefixes = var.address_prefixes != null ? length(var.address_prefixes) > 1 : false
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
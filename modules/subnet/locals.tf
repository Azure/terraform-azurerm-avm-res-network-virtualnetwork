locals {
  ipam_enabled = var.ipam_pools != null
  # Subscription scope used by the interfaces module to resolve role definition
  # names to resource ids. Derived from the virtual network parent_id.
  role_assignment_definition_scope = "/subscriptions/${split("/", var.parent_id)[2]}"
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

locals {
  ipam_enabled                       = var.ipam_pools != null
  ipam_ignore_rt_enabled             = local.ipam_enabled && var.ignore_route_table_changes
  ipam_managed_enabled               = local.ipam_enabled && !var.ignore_route_table_changes
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  subnet_ignore_rt_enabled           = !local.ipam_enabled && var.ignore_route_table_changes
  subnet_managed_enabled             = !local.ipam_enabled && !var.ignore_route_table_changes
  # Coalesced subnet resource id, used by role assignments and outputs.
  subnet_id = local.ipam_managed_enabled ? azapi_resource.subnet_ipam[0].id : (
    local.ipam_ignore_rt_enabled ? azapi_resource.subnet_ipam_ignore_route_table[0].id : (
      local.subnet_ignore_rt_enabled ? azapi_resource.subnet_ignore_route_table[0].id : azapi_resource.subnet[0].id
    )
  )
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

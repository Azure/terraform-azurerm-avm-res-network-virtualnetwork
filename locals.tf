locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"

  diagnostic_settings = {
    for k, v in var.diagnostic_settings : k => merge(v, { name = coalesce(v.name, k) })
  }

  lock = var.lock == null ? null : merge(var.lock, { name = coalesce(var.lock.name, "lock-${lower(var.lock.kind)}") })
}

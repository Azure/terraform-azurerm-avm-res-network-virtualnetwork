locals {
  has_parent_id                      = var.parent_id != null
  parent_id                          = local.has_parent_id ? var.parent_id : "/subscriptions/${local.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  subscription_id                    = local.has_parent_id ? null : (var.subscription_id == null ? data.azurerm_client_config.this[0].subscription_id : var.subscription_id)
}

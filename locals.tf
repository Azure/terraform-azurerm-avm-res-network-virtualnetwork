
locals {
  enable_telemetry                   = var.enable_telemetry
  resource_group_name                = coalesce(try(var.existing_vnet.id[4], null), var.resource_group_name)
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  subscription_id                    = coalesce(try(var.existing_vnet.id[2], null), var.subscription_id, data.azurerm_client_config.this.subscription_id)
  vnet_name                          = var.existing_vnet == null ? var.name : split("/", var.existing_vnet.id)[8]
  vnet_resource_id                   = "/subscriptions/${local.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}"
}

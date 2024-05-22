locals {
  enable_telemetry                   = var.enable_telemetry && !var.use_existing_virtual_network
  output_virtual_network_name        = var.use_existing_virtual_network ? var.name : azapi_resource.vnet[0].name
  output_virtual_network_resource    = var.use_existing_virtual_network ? null : azapi_resource.vnet[0]
  output_virtual_network_resource_id = var.use_existing_virtual_network ? local.vnet_resource_id : azapi_resource.vnet[0].id
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  subscription_id                    = coalesce(var.subscription_id, data.azurerm_client_config.this.subscription_id)
  vnet_resource_id                   = "/subscriptions/${local.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.name}"
}

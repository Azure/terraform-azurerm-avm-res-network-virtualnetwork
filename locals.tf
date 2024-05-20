locals {
  enable_telemetry                   = var.enable_telemetry && var.existing_virtual_network == null
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  subscription_id                    = coalesce(var.subscription_id, data.azurerm_client_config.this.subscription_id)
  vnet_resource_id                   = var.existing_virtual_network == null ? "/subscriptions/${local.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.name}" : ""
}

locals {
  output_vnet_name        = var.existing_virtual_network == null ? azapi_resource.vnet[0].name : split("/", var.existing_virtual_network.resource_id)[8]
  output_vnet_resource    = var.existing_virtual_network == null ? azapi_resource.vnet[0] : null
  output_vnet_resource_id = var.existing_virtual_network == null ? azapi_resource.vnet[0].id : var.existing_virtual_network.resource_id
}
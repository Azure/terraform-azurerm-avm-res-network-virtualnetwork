locals {
  enable_telemetry                   = var.enable_telemetry
  output_virtual_network_name        = azapi_resource.vnet[0].name
  output_virtual_network_resource    = azapi_resource.vnet[0]
  output_virtual_network_resource_id = azapi_resource.vnet[0].id
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  subscription_id                    = coalesce(var.subscription_id, data.azurerm_client_config.this.subscription_id)
}

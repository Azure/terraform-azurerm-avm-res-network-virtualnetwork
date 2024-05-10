
locals {
  enable_telemetry                   = var.enable_telemetry
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  vnet_name                          = var.existing_vnet == null ? var.name : var.existing_vnet.name
}

data "azurerm_client_config" "current" {}

locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

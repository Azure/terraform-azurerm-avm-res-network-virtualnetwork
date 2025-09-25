data "azurerm_client_config" "this" {
  count = local.has_parent_id ? 0 : 1
}

data "azurerm_client_config" "this" {}

data "azurerm_resource_group" "tags" {
  count = var.tag_inheritance == null ? 0 : (var.tag_inheritance.resource_group ? 1 : 0)

  name = var.resource_group_name
}

data "azurerm_subscription" "tags" {
  count = var.tag_inheritance == null ? 0 : (var.tag_inheritance.subscription ? 1 : 0)

  subscription_id = local.subscription_id
}

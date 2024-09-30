locals {
  inherited_tags_resource_group      = var.tag_inheritance == null ? {} : (var.tag_inheritance.resource_group ? data.azurerm_resource_group.tags[0].tags : {})
  inherited_tags_subscription        = var.tag_inheritance == null ? {} : (var.tag_inheritance.subscription ? data.azurerm_subscription.tags[0].tags : {})
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  subscription_id                    = coalesce(var.subscription_id, data.azurerm_client_config.this.subscription_id)
  tags                               = merge(local.inherited_tags_subscription, local.inherited_tags_resource_group, var.tags)
}

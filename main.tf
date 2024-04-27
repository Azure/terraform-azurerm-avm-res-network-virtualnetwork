data "azurerm_subscription" "this" {}

# Azure Generic vNet Module
# Creating a Virtual Network with the specified configurations.
resource "azurerm_virtual_network" "this" {
  count = var.existing_parent_resource == null ? 1 : 0

  address_space       = var.virtual_network_address_space
  location            = var.location
  name                = local.vnet_name
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Configuring DDoS protection plan if provided.
  dynamic "ddos_protection_plan" {
    for_each = var.virtual_network_ddos_protection_plan != null ? [var.virtual_network_ddos_protection_plan] : []

    content {
      enable = ddos_protection_plan.value.enable
      id     = ddos_protection_plan.value.id
    }
  }
}

resource "azurerm_virtual_network_dns_servers" "vnet_dns" {
  count = var.virtual_network_dns_servers != null ? 1 : 0

  virtual_network_id = "/subscriptions/${data.azurerm_subscription.this.id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}"
  dns_servers        = var.virtual_network_dns_servers.dns_servers

  depends_on = [azurerm_virtual_network.this]
}

resource "azurerm_virtual_network_peering" "vnet_peering" {
  for_each = var.vnet_peering_config

  name                      = "peering-${each.key}"
  remote_virtual_network_id = each.value.remote_vnet_id
  resource_group_name       = var.resource_group_name # Assuming you have a variable for the resource group
  virtual_network_name      = local.vnet_name         # Reference to your virtual network
  allow_forwarded_traffic   = each.value.allow_forwarded_traffic
  allow_gateway_transit     = each.value.allow_gateway_transit
  use_remote_gateways       = each.value.use_remote_gateways

  depends_on = [azurerm_virtual_network.this]
}



# Applying Management Lock to the Virtual Network if specified.
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_virtual_network.this[0].id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}


# Assigning Roles to the Virtual Network based on the provided configurations.
resource "azurerm_role_assignment" "vnet_level" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = "/subscriptions/${data.azurerm_subscription.this.id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}"
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check

  depends_on = [azurerm_virtual_network.this]
}

# Create diagonostic settings for the virtual network
resource "azurerm_monitor_diagnostic_setting" "example" {
  # Filter out entries that don't have any of the required attributes set
  for_each = {
    for key, value in var.diagnostic_settings : key => value
    if value.workspace_resource_id != null || value.storage_account_resource_id != null || value.event_hub_authorization_rule_resource_id != null
  }

  name                           = each.value.name != null ? each.value.name : "defaultDiagnosticSetting"
  target_resource_id             = "/subscriptions/${data.azurerm_subscription.this.id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}"
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id != null ? each.value.event_hub_authorization_rule_resource_id : null
  eventhub_name                  = each.value.event_hub_name != null ? each.value.event_hub_name : null
  log_analytics_workspace_id     = each.value.workspace_resource_id != null ? each.value.workspace_resource_id : null
  storage_account_id             = each.value.storage_account_resource_id != null ? each.value.storage_account_resource_id : null

  dynamic "enabled_log" {
    for_each = each.value.log_categories_and_groups
    content {
      category = enabled_log.value

      retention_policy {
        enabled = false
      }
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }

  depends_on = [azurerm_virtual_network.this]
}


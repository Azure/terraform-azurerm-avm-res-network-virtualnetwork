data "azurerm_subscription" "this" {}

# azapi_resource.vnet are the virtual networks that will be created
# lifecycle ignore changes to the body to prevent subnets being deleted
# see <https://github.com/Azure/terraform-azurerm-lz-vending/issues/45> for more information 
resource "azapi_resource" "vnet" {
  count     = var.existing_parent_resource == null ? 1 : 0
  parent_id = "${data.azurerm_subscription.this.id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.Network/virtualNetworks@2021-08-01"
  name      = var.name
  location  = var.location
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = var.address_space
      }
      dhcpOptions = var.dns_servers != null ? {
        dnsServers = var.dns_servers.dns_servers
      } : null

      ddosProtectionPlan = var.ddos_protection_plan != null ? {
        id = var.ddos_protection_plan.id
      } : null
      enableDdosProtection = var.ddos_protection_plan != null ? var.ddos_protection_plan.enable : false
    }
  }
  tags = var.tags
  lifecycle {
    ignore_changes = [body, tags]
  }
}

# azapi_update_resource.vnet are the virtual networks that will be created
# This is a workaround to allow updates to the virtual network without deleting the subnets created elsewhere.
# see <https://github.com/Azure/terraform-azurerm-lz-vending/issues/45> for more information 
resource "azapi_update_resource" "vnet" {
  count       = var.existing_parent_resource == null ? 1 : 0
  resource_id = azapi_resource.vnet[0].id
  type        = "Microsoft.Network/virtualNetworks@2021-08-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = var.address_space
      }
      dhcpOptions = var.dns_servers != null ? {
        dnsServers = var.dns_servers.dns_servers
      } : null
      ddosProtectionPlan = var.ddos_protection_plan != null ? {
        id = var.ddos_protection_plan.id
      } : null
      enableDdosProtection = var.ddos_protection_plan != null ? var.ddos_protection_plan.enable : false
    },
    tags = var.tags
  }
}

resource "time_sleep" "wait_for_vnet_before_subnet_operations" {
  create_duration  = var.wait_for_vnet_before_subnet_operations.create
  destroy_duration = var.wait_for_vnet_before_subnet_operations.destroy

  depends_on = [
    azapi_update_resource.vnet
  ]
}

resource "azurerm_virtual_network_peering" "vnet_peering" {
  for_each = var.peerings

  name                         = each.value.name
  remote_virtual_network_id    = each.value.remote_virtual_network_id
  resource_group_name          = var.resource_group_name # Assuming you have a variable for the resource group
  virtual_network_name         = local.vnet_name         # Reference to your virtual network
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  allow_virtual_network_access = each.value.allow_virtual_network_access
  use_remote_gateways          = each.value.use_remote_gateways

  depends_on = [
    azapi_resource.vnet,
    azapi_update_resource.vnet,
  ]
}



# Applying Management Lock to the Virtual Network if specified.
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.vnet[0].id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."

  depends_on = [
    azapi_resource.vnet,
    azapi_update_resource.vnet,
  ]
}


# Assigning Roles to the Virtual Network based on the provided configurations.
resource "azurerm_role_assignment" "vnet_level" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = "${data.azurerm_subscription.this.id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}"
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check

  depends_on = [
    azapi_resource.vnet,
    azapi_update_resource.vnet,
  ]
}

# Create diagonostic settings for the virtual network
resource "azurerm_monitor_diagnostic_setting" "example" {
  # Filter out entries that don't have any of the required attributes set
  for_each = {
    for key, value in var.diagnostic_settings : key => value
    if value.workspace_resource_id != null || value.storage_account_resource_id != null || value.event_hub_authorization_rule_resource_id != null
  }

  name                           = each.value.name != null ? each.value.name : "defaultDiagnosticSetting"
  target_resource_id             = "${data.azurerm_subscription.this.id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}"
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id != null ? each.value.event_hub_authorization_rule_resource_id : null
  eventhub_name                  = each.value.event_hub_name != null ? each.value.event_hub_name : null
  log_analytics_workspace_id     = each.value.workspace_resource_id != null ? each.value.workspace_resource_id : null
  storage_account_id             = each.value.storage_account_resource_id != null ? each.value.storage_account_resource_id : null

  dynamic "enabled_log" {
    for_each = each.value.log_categories_and_groups
    content {
      category = enabled_log.value
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }

  depends_on = [
    azapi_resource.vnet,
    azapi_update_resource.vnet,
  ]
}


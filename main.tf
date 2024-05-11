data "azurerm_client_config" "this" {}

# azapi_resource.vnet are the virtual networks that will be created
# lifecycle ignore changes to the body to prevent subnets being deleted
# see <https://github.com/Azure/terraform-azurerm-lz-vending/issues/45> for more information 
resource "azapi_resource" "vnet" {
  count = var.existing_vnet == null ? 1 : 0

  type = "Microsoft.Network/virtualNetworks@2021-08-01"
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
  location                  = var.location
  name                      = var.name
  parent_id                 = "/subscriptions/${local.subscription_id}/resourceGroups/${local.resource_group_name}"
  schema_validation_enabled = true
  tags                      = var.tags

  lifecycle {
    ignore_changes = [body, tags]

    precondition {
      condition     = var.name != null && var.address_space != null && var.existing_vnet == null
      error_message = "`var.name` and `var.address_space` must be specified unless `var.existing_vnet` is supplied."
    }
  }
}

# azapi_update_resource.vnet are the virtual networks that will be created
# This is a workaround to allow updates to the virtual network without deleting the subnets created elsewhere.
# see <https://github.com/Azure/terraform-azurerm-lz-vending/issues/45> for more information 
resource "azapi_update_resource" "vnet" {
  count = var.existing_vnet == null ? 1 : 0

  type = "Microsoft.Network/virtualNetworks@2021-08-01"
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
  resource_id = azapi_resource.vnet[0].id
}

resource "azapi_resource" "vnet_peering" {
  for_each = var.peerings

  type = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01"
  body = {
    properties = {
      allowVirtualNetworkAccess = each.value.allow_virtual_network_access
      allowForwardedTraffic     = each.value.allow_forwarded_traffic
      allowGatewayTransit       = each.value.allow_gateway_transit
      useRemoteGateways         = each.value.use_remote_gateways
    }
  }
  locks                     = [local.vnet_resource_id]
  name                      = each.value.name
  parent_id                 = local.vnet_resource_id
  schema_validation_enabled = true

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
  scope                                  = local.vnet_resource_id
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
  target_resource_id             = local.vnet_resource_id
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


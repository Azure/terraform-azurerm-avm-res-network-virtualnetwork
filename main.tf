# Azure Generic vNet Module

# Creating a Virtual Network with the specified configurations.

resource "azurerm_network_ddos_protection_plan" "this" {
  count = var.new_network_ddos_protection_plan == null ? 0 : 1

  location            = var.vnet_location
  name                = var.new_network_ddos_protection_plan.name
  resource_group_name = var.resource_group_name
  
  dynamic "timeouts" {
    for_each = var.new_network_ddos_protection_plan.timeouts == null ? [] : [var.new_network_ddos_protection_plan.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
resource "azurerm_virtual_network" "vnet" {
  address_space       = var.virtual_network_address_space
  location            = var.vnet_location
  name                = var.vnet_name
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
  dynamic "ddos_protection_plan" {
    for_each = azurerm_network_ddos_protection_plan.this
    content {
      enable = true
      id     = ddos_protection_plan.value.id
    }
  }

  lifecycle {
    precondition {
      condition     = var.virtual_network_ddos_protection_plan == null || var.new_network_ddos_protection_plan == null
      error_message = "Cannot set both of `var.virtual_network_ddos_protection_plan` and `var.new_network_ddos_protection_plan`"
    }
  }
}

resource "azurerm_virtual_network_dns_servers" "vnet_dns" {
  count = var.virtual_network_dns_servers == null ? 0 : 1

  virtual_network_id = azurerm_virtual_network.vnet.id
  dns_servers        = var.virtual_network_dns_servers.dns_servers
}


# Creating Subnets within the Virtual Network.
resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  address_prefixes                              = each.value.address_prefixes
  name                                          = each.key
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  private_endpoint_network_policies_enabled     = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  service_endpoint_policy_ids                   = each.value.service_endpoint_policy_ids
  service_endpoints                             = each.value.service_endpoints

  dynamic "delegation" {
    for_each = each.value.delegations == null ? [] : each.value.delegations

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }

  # Do not remove this `depends_on` or we'll met a parallel related issue that failed the creation of `azurerm_subnet_route_table_association` and `azurerm_subnet_network_security_group_association`
  depends_on = [azurerm_virtual_network_dns_servers.vnet_dns]
}

locals {
  azurerm_subnet_name2id = {
    for index, subnet in azurerm_subnet.subnet :
    subnet.name => subnet.id
  }
}

resource "azurerm_subnet_network_security_group_association" "vnet" {
  for_each = local.subnet_with_network_security_group

  network_security_group_id = each.value
  subnet_id                 = local.azurerm_subnet_name2id[each.key]
}

resource "azurerm_subnet_route_table_association" "vnet" {
  for_each = local.subnets_with_route_table

  route_table_id = each.value
  subnet_id      = local.azurerm_subnet_name2id[each.key]
}

resource "azurerm_subnet_nat_gateway_association" "nat_gw" {
  for_each = local.subnet_with_nat_gateway

  nat_gateway_id = each.value
  subnet_id      = local.azurerm_subnet_name2id[each.key]
}

resource "azurerm_virtual_network_peering" "vnet_peering" {
  for_each = var.vnet_peering_config

  name                  = "peering-${each.key}"
  resource_group_name   = var.resource_group_name  # Assuming you have a variable for the resource group
  virtual_network_name  = azurerm_virtual_network.vnet.name  # Reference to your virtual network
  remote_virtual_network_id = each.value.remote_vnet_id
  allow_forwarded_traffic   = each.value.allow_forwarded_traffic
  allow_gateway_transit     = each.value.allow_gateway_transit
  use_remote_gateways       = each.value.use_remote_gateways
}







# Applying Management Lock to the Virtual Network if specified.
resource "azurerm_management_lock" "this" {
  count      = var.lock.kind != "None" ? 1 : 0
  name       = coalesce(var.lock.name, "lock-${var.vnet_name}")
  scope      = azurerm_virtual_network.vnet.id
  lock_level = var.lock.kind
}

# Assigning Roles to the Virtual Network based on the provided configurations.
resource "azurerm_role_assignment" "this" {
  for_each                               = var.role_assignments
  scope                                  = azurerm_virtual_network.vnet.id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  principal_id                           = each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}

# Create diagonostic settings for the virtual network
resource "azurerm_monitor_diagnostic_setting" "example" {
  # Filter out entries that don't have any of the required attributes set
  for_each = {
    for key, value in var.diagnostic_settings : key => value
    if value.workspace_resource_id != null || value.storage_account_resource_id != null || value.event_hub_authorization_rule_resource_id != null
  }

  name               = each.value.name != null ? each.value.name : "defaultDiagnosticSetting"
  target_resource_id = azurerm_virtual_network.vnet.id

  log_analytics_workspace_id     = each.value.workspace_resource_id != null ? each.value.workspace_resource_id : null
  storage_account_id             = each.value.storage_account_resource_id != null ? each.value.storage_account_resource_id : null
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id != null ? each.value.event_hub_authorization_rule_resource_id : null
  eventhub_name                  = each.value.event_hub_name != null ? each.value.event_hub_name : null

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
}


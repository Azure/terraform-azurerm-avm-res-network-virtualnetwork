# Azure Generic vNet Module

# Creating a Virtual Network with the specified configurations.
resource "azurerm_virtual_network" "vnet" {
  address_space       = length(var.address_spaces) == 0 ? [var.address_space] : var.address_spaces
  location            = var.vnet_location
  name                = var.name
  resource_group_name = var.resource_group_name
  dns_servers         = var.dns_servers
  tags                = var.tags

  # Configuring DDoS protection plan if provided.
  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan != null ? [var.ddos_protection_plan] : []
    content {
      enable = ddos_protection_plan.value.enable
      id     = ddos_protection_plan.value.id
    }
  }
}

# Creating Subnets within the Virtual Network.
resource "azurerm_subnet" "subnet" {
  for_each                                      = toset(var.subnet_names)
  address_prefixes                              = [local.subnet_names_prefixes_map[each.value]]
  name                                          = each.value
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  private_endpoint_network_policies_enabled     = lookup(var.private_link_endpoint_network_policies_enabled, each.value, false)
  private_link_service_network_policies_enabled = lookup(var.private_link_service_network_policies_enabled, each.value, false)
  service_endpoints                             = lookup(var.subnet_service_endpoints, each.value, [])

  # Configuring Subnet Delegation if provided.
  dynamic "delegation" {
    for_each = lookup(var.subnet_delegation, each.value, [])
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# Creating a local map of subnet names to their IDs.
locals {
  azurerm_subnets_name_id_map = { for s in azurerm_subnet.subnet : s.name => s.id }
}

# Associating Network Security Groups to Subnets.
resource "azurerm_subnet_network_security_group_association" "vnet" {
  for_each                  = var.nsg_ids
  network_security_group_id = each.value
  subnet_id                 = local.azurerm_subnets_name_id_map[each.key]
}

# Associating Route Tables to Subnets.
resource "azurerm_subnet_route_table_association" "vnet" {
  for_each       = var.route_tables_ids
  route_table_id = each.value
  subnet_id      = local.azurerm_subnets_name_id_map[each.key]
}

# Applying Management Lock to the Virtual Network if specified.
resource "azurerm_management_lock" "this" {
  count      = var.lock.kind != "None" ? 1 : 0
  name       = coalesce(var.lock.name, "lock-${var.name}")
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

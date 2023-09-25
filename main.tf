
#Azure Generic vNet Module
data "azurerm_resource_group" "existing_rg" {
  name = var.resource_group_name
}
resource "azurerm_virtual_network" "vnet" {
  address_space       = length(var.address_spaces) == 0 ? [var.address_space] : var.address_spaces
  location            = var.vnet_location
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  dns_servers         = var.dns_servers
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan != null ? [var.ddos_protection_plan] : []

    content {
      enable = ddos_protection_plan.value.enable
      id     = ddos_protection_plan.value.id
    }
  }
}
resource "azurerm_subnet" "subnet" {
  for_each                                      = toset(var.subnet_names)
  address_prefixes                              = [local.subnet_names_prefixes_map[each.value]]
  name                                          = each.value
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  private_endpoint_network_policies_enabled     = lookup(var.private_link_endpoint_network_policies_enabled, each.value, false)
  private_link_service_network_policies_enabled = lookup(var.private_link_service_network_policies_enabled, each.value, false)
  service_endpoints                             = lookup(var.subnet_service_endpoints, each.value, [])
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

locals {
  azurerm_subnets_name_id_map = { for s in azurerm_subnet.subnet : s.name => s.id }
}

resource "azurerm_subnet_network_security_group_association" "vnet" {
  for_each = var.nsg_ids

  network_security_group_id = each.value
  subnet_id                 = local.azurerm_subnets_name_id_map[each.key]
}
resource "azurerm_subnet_route_table_association" "vnet" {
  for_each = var.route_tables_ids

  route_table_id = each.value
  subnet_id      = local.azurerm_subnets_name_id_map[each.key]
}

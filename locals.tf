
locals {
  existing_resource_group_name       = var.existing_virtual_network != null ? split("/", var.existing_virtual_network.id)[4] : var.resource_group_name
  existing_vnet_name                 = var.existing_virtual_network != null ? split("/", var.existing_virtual_network.id)[8] : ""
  resource_group_name                = var.existing_virtual_network != null ? local.existing_resource_group_name : var.resource_group_name
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  subnet_with_nat_gateway = {
    for name, subnet in var.subnets :
    name => subnet.nat_gateway.id
    if subnet.nat_gateway != null
  }
  subnet_with_network_security_group = {
    for name, subnet in var.subnets :
    name => subnet.network_security_group.id
    if subnet.network_security_group != null
  }
  subnets_with_route_table = {
    for name, subnet in var.subnets :
    name => subnet.route_table.id
    if subnet.route_table != null
  }
  vnet_name = var.existing_virtual_network != null ? local.existing_vnet_name : var.name
}

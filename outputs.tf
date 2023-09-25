output "vnet_address_space" {
  description = "The address space of the newly created vNet"
  value       = azurerm_virtual_network.vnet.address_space
}

output "vnet_id" {
  description = "The id of the newly created vNet"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_location" {
  description = "The location of the newly created vNet"
  value       = azurerm_virtual_network.vnet.location
}

output "vnet_name" {
  description = "The name of the newly created vNet"
  value       = azurerm_virtual_network.vnet.name
}

//output subnet ids
output "subnet_ids" {
  description = "The ids of the newly created subnets"
  value       = { for k, v in azurerm_subnet.subnet : k => v.id }
}

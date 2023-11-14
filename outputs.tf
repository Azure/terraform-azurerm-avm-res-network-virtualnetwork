
output "name" {
  description = "The name of the newly created vNet"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  description = "The id of the newly created vNet"
  value       = azurerm_virtual_network.vnet.id
}
output "vnet_address_space" {
  description = "The address space of the newly created vNet"
  value       = azurerm_virtual_network.vnet.address_space
}

//output subnet ids
output "subnet_ids" {
  description = "The ids of the newly created subnets"
  value       = { for k, v in azurerm_subnet.subnet : k => v.id }
}

output "subnet_names" {
  description = "The names of the newly created subnets"
  value       = { for k, v in azurerm_subnet.subnet : k => v.name }
}


output "subnet_address_prefixes" {
  description = "The address prefixes of the newly created subnets"
  value       = flatten([for s in values(azurerm_subnet.subnet) : s.address_prefixes])
}


output "vnet_location" {
  description = "The location of the newly created vNet"
  value       = azurerm_virtual_network.vnet.location
}



output "resource" {
  value       = azurerm_virtual_network.vnet
  description = "This is the full resource output for the virtual network resource."
}
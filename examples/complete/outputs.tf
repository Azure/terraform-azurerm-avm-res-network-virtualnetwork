#Output vnet id
output "vnet_id" {
  description = "The resource ID of the virtual network."
  value       = module.vnet_1.virtual_network_id
}

#Output vnet name
output "vnet_name" {
  description = "The name of the virtual network."
  value       = module.vnet_1.vnet_resource
}

#Output vnet id
output "id" {
  description = "The resource ID of the virtual network."
  value       = module.vnet_1.id
}

#Output vnet resource information
output "resource" {
  description = "The name of the virtual network."
  value       = module.vnet_1.resource
}

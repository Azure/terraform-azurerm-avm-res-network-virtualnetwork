#Output vnet id
output "id" {
  description = "The resource ID of the virtual network."
  value       = module.vnet1.resource_id
}

#Output vnet resource information
output "resource" {
  description = "The virtual network resource."
  value       = module.vnet1.resource
}

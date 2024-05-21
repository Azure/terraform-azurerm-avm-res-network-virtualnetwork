#Output vnet resource information
output "resource" {
  description = "The virtual network resource."
  value       = module.vnet1.resource
}

#Output vnet name
output "name" {
  description = "The resource name of the virtual network."
  value       = module.vnet1.name
}

#Output subnets
output "subnets" {
  description = "Information about the subnets created in the module."
  value = module.vnet1.subnets
}

#Output vnet resource id
output "resource_id" {
  description = "The resource ID of the virtual network."
  value       = module.vnet1.resource_id
}

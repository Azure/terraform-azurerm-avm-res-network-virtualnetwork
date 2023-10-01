
output "name" {
  description = "The name of the newly created vNet"
  value       = module.vnet.name
}

output "vnet_id" {
  description = "The id of the newly created vNet"
  value       = module.vnet.vnet_id
}

output "vnet_address_space" {
  description = "The address space of the newly created vNet"
  value       = module.vnet.vnet_address_space
}

output "subnet_names" {
  description = "The names of the newly created subnets"
  value = { for name in module.vnet.subnet_names: name => name }
} 

output "subnet_address_prefixes" {
  description = "The address prefixes of the newly created subnets"
  value = { for prefix in module.vnet.subnet_address_prefixes: prefix => prefix }
}


output "vnet_location" {
  description = "The location of the newly created vNet"
  value       = module.vnet.vnet_location
}




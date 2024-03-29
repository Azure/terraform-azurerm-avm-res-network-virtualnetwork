output "subnets" {
  description = "Information about the subnets created in the module."
  value       = module.create_subnet.subnets
}

output "vnet_id" {
  description = "The id of the virtual network"
  value       = module.create_vnet.virtual_network_id
}

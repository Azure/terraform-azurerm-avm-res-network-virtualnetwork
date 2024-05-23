output "name" {
  description = "The resource name of the virtual network."
  value       = local.output_virtual_network_name
}

output "resource" {
  description = "The Azure Virtual Network resource.  This will be null if an existing vnet is supplied."
  value       = local.output_virtual_network_resource
}

output "resource_id" {
  description = "The resource ID of the virtual network."
  value       = local.output_virtual_network_resource_id
}

output "subnets" {
  description = <<DESCRIPTION
Information about the subnets created in the module.
DESCRIPTION
  value       = module.subnet
}

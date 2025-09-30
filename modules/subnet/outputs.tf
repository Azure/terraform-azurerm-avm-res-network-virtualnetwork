output "address_prefixes" {
  description = "The address prefixes of the subnet. For IPAM subnets, this shows the dynamically allocated ranges."
  value       = var.ipam_pools != null ? try(azapi_resource.ipam_subnet[0].output.properties.addressPrefixes, []) : (var.address_prefixes != null ? var.address_prefixes : (var.address_prefix != null ? [var.address_prefix] : []))
}

output "application_gateway_ip_configuration_resource_id" {
  description = "The application gateway ip configurations resource id."
  value       = var.ipam_pools != null ? try(azapi_resource.ipam_subnet[0].body.properties.applicationGatewayIPConfigurations.id, null) : try(azapi_resource.subnet[0].body.properties.applicationGatewayIPConfigurations.id, null)
}

output "name" {
  description = "The resource name of the subnet."
  value       = var.ipam_pools != null ? azapi_resource.ipam_subnet[0].name : azapi_resource.subnet[0].name
}

output "resource" {
  description = "All attributes of the subnet"
  value       = var.ipam_pools != null ? azapi_resource.ipam_subnet[0] : azapi_resource.subnet[0]
}

output "resource_id" {
  description = "The resource ID of the subnet."
  value       = var.ipam_pools != null ? azapi_resource.ipam_subnet[0].id : azapi_resource.subnet[0].id
}

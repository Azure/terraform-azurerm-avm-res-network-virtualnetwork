output "address_prefixes" {
  description = "The address prefixes of the subnet. For IPAM subnets, this shows the dynamically allocated ranges."
  value       = local.ipam_enabled ? azapi_resource.subnet_ipam[0].output.properties.addressPrefixes : azapi_resource.subnet[0].output.properties.addressPrefixes
}

output "application_gateway_ip_configuration_resource_id" {
  description = "The application gateway ip configurations resource id."
  value       = try(azapi_resource.subnet.body.properties.applicationGatewayIPConfigurations.id, null)
}

output "name" {
  description = "The resource name of the subnet."
  value       = azapi_resource.subnet.name
}

output "resource" {
  description = "All attributes of the subnet"
  value       = azapi_resource.subnet
}

output "resource_id" {
  description = "The resource ID of the subnet."
  value       = azapi_resource.subnet.id
}

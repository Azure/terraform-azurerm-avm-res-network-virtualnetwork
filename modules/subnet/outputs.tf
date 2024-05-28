output "application_gateway_ip_configuration_resource_id" {
  description = "The application gateway ip configurations resource id."
  value       = try(azapi_resource.subnet.body.properties.applicationGatewayIPConfigurations.id, null)
}

output "resource" {
  description = "All attributes of the subnet"
  value       = azapi_resource.subnet
}

output "resource_id" {
  description = "The resource ID of the subnet."
  value       = azapi_resource.subnet.id
}

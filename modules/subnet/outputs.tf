output "application_gateway_ip_configuration_resource_id" {
  value = try(azapi_resource.subnet.body.properties.applicationGatewayIPConfigurations.id, null)
}

output "resource_id" {
  value = azapi_resource.subnet.id
}

output "address_prefixes" {
  description = "The address prefixes of the subnet. For IPAM subnets, this shows the dynamically allocated ranges."
  value = local.ipam_enabled ? azapi_resource.subnet_ipam[0].output.properties.addressPrefixes : try(
    azapi_resource.subnet[0].output.properties.addressPrefixes,
    [azapi_resource.subnet[0].output.properties.addressPrefix],
    azapi_resource.subnet[0].body.properties.addressPrefixes,
    [azapi_resource.subnet[0].body.properties.addressPrefix]
  )
}

output "application_gateway_ip_configuration_resource_id" {
  description = "The application gateway ip configurations resource id."
  value       = local.ipam_enabled ? try(azapi_resource.subnet_ipam[0].body.properties.applicationGatewayIPConfigurations.id, null) : try(azapi_resource.subnet[0].body.properties.applicationGatewayIPConfigurations.id, null)
}

output "name" {
  description = "The resource name of the subnet."
  value       = local.ipam_enabled ? azapi_resource.subnet_ipam[0].name : azapi_resource.subnet[0].name
}

output "resource" {
  description = "All attributes of the subnet"
  value       = local.ipam_enabled ? azapi_resource.subnet_ipam[0] : azapi_resource.subnet[0]
}

output "resource_id" {
  description = "The resource ID of the subnet."
  value       = local.ipam_enabled ? azapi_resource.subnet_ipam[0].id : azapi_resource.subnet[0].id
}

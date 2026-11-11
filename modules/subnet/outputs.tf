output "address_prefixes" {
  description = "The address prefixes of the subnet. For IPAM subnets, this shows the dynamically allocated ranges."
  value = local.ipam_enabled ? local.subnet_resource.output.properties.addressPrefixes : try(
    local.subnet_resource.output.properties.addressPrefixes,
    [local.subnet_resource.output.properties.addressPrefix],
    local.subnet_resource.body.properties.addressPrefixes,
    [local.subnet_resource.body.properties.addressPrefix]
  )
}

output "application_gateway_ip_configuration_resource_id" {
  description = "The application gateway ip configurations resource id."
  value       = local.ipam_enabled ? try(local.subnet_resource.body.properties.applicationGatewayIPConfigurations.id, null) : try(local.subnet_resource.body.properties.applicationGatewayIPConfigurations.id, null)
}

output "name" {
  description = "The resource name of the subnet."
  value       = local.ipam_enabled ? local.subnet_resource.name : local.subnet_resource.name
}

output "resource" {
  description = "All attributes of the subnet"
  value       = local.ipam_enabled ? local.subnet_resource : local.subnet_resource
}

output "resource_id" {
  description = "The resource ID of the subnet."
  value       = local.ipam_enabled ? local.subnet_resource.id : local.subnet_resource.id
}

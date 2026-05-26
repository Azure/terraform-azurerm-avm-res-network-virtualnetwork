output "address_prefixes" {
  description = "The address prefixes of the subnet. For IPAM subnets, this shows the dynamically allocated ranges."
  value = local.ipam_managed_enabled ? azapi_resource.subnet_ipam[0].output.properties.addressPrefixes : (
    local.ipam_ignore_rt_enabled ? azapi_resource.subnet_ipam_ignore_route_table[0].output.properties.addressPrefixes : (
      local.subnet_ignore_rt_enabled ? try(
        azapi_resource.subnet_ignore_route_table[0].output.properties.addressPrefixes,
        [azapi_resource.subnet_ignore_route_table[0].output.properties.addressPrefix],
        azapi_resource.subnet_ignore_route_table[0].body.properties.addressPrefixes,
        [azapi_resource.subnet_ignore_route_table[0].body.properties.addressPrefix]
        ) : try(
        azapi_resource.subnet[0].output.properties.addressPrefixes,
        [azapi_resource.subnet[0].output.properties.addressPrefix],
        azapi_resource.subnet[0].body.properties.addressPrefixes,
        [azapi_resource.subnet[0].body.properties.addressPrefix]
      )
    )
  )
}

output "application_gateway_ip_configuration_resource_id" {
  description = "The application gateway ip configurations resource id."
  value = local.ipam_managed_enabled ? try(azapi_resource.subnet_ipam[0].body.properties.applicationGatewayIPConfigurations.id, null) : (
    local.ipam_ignore_rt_enabled ? try(azapi_resource.subnet_ipam_ignore_route_table[0].body.properties.applicationGatewayIPConfigurations.id, null) : (
      local.subnet_ignore_rt_enabled ? try(azapi_resource.subnet_ignore_route_table[0].body.properties.applicationGatewayIPConfigurations.id, null) : try(azapi_resource.subnet[0].body.properties.applicationGatewayIPConfigurations.id, null)
    )
  )
}

output "name" {
  description = "The resource name of the subnet."
  value       = var.name
}

output "resource" {
  description = "All attributes of the subnet"
  value = local.ipam_managed_enabled ? azapi_resource.subnet_ipam[0] : (
    local.ipam_ignore_rt_enabled ? azapi_resource.subnet_ipam_ignore_route_table[0] : (
      local.subnet_ignore_rt_enabled ? azapi_resource.subnet_ignore_route_table[0] : azapi_resource.subnet[0]
    )
  )
}

output "resource_id" {
  description = "The resource ID of the subnet."
  value       = local.subnet_id
}

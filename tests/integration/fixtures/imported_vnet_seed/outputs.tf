output "resource_group_id" {
  value       = azapi_resource.resource_group.id
  description = "Resource group ID containing the VNet to import."
}

output "location" {
  value       = azapi_resource.resource_group.location
  description = "Azure region used by the imported VNet."
}

output "vnet_id" {
  value       = azapi_resource.existing_vnet.id
  description = "Azure ID of the VNet created outside the module."
}

output "resource_group_id" {
  description = "Resource group ID containing the VNet to import."
  value       = azapi_resource.resource_group.id
}

output "location" {
  description = "Azure region used by the imported VNet."
  value       = azapi_resource.resource_group.location
}

output "vnet_id" {
  description = "Azure ID of the VNet created outside the module."
  value       = azapi_resource.existing_vnet.id
}

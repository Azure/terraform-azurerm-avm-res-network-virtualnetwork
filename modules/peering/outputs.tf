output "name" {
  description = "The name of the peering resource"
  value       = azapi_resource.this.name
}

output "resource" {
  description = "All attributes of the peering resource"
  value       = azapi_resource.this
}

output "resource_id" {
  description = "The resource ID of the peering resource."
  value       = azapi_resource.this.id
}

output "reverse_name" {
  description = "The name of the reverse peering resource"
  value       = var.create_reverse_peering ? azapi_resource.reverse[0].name : null
}

output "reverse_resource" {
  description = "All attributes of the reverse peering resource"
  value       = var.create_reverse_peering ? azapi_resource.reverse[0] : null
}

output "reverse_resource_id" {
  description = "The resource ID of the reverse peering resource."
  value       = var.create_reverse_peering ? azapi_resource.reverse[0].id : null
}

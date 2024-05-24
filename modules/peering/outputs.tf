output "resource" {
  description = "All attributes of the peering resource"
  value       = azapi_resource.this
}

output "resource_id" {
  description = "The resource ID of the peering resource."
  value       = azapi_resource.this.id
}

output "resource_id" {
  description = "The resource ID of the reverse peering resource."
  value       = azapi_resource.reverse.id
}

output "reverse_resource" {
  description = "All attributes of the reverse peering resource"
  value       = azapi_resource.reverse
}

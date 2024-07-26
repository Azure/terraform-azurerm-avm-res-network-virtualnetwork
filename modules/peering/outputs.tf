output "name" {
  description = "The name of the peering resource"
  value       = local.output_resource_name
}

output "resource_id" {
  description = "The resource ID of the peering resource."
  value       = local.output_resource_id
}

output "reverse_name" {
  description = "The name of the reverse peering resource"
  value       = local.output_reverse_resource_name
}

output "reverse_resource_id" {
  description = "The resource ID of the reverse peering resource."
  value       = local.output_reverse_resource_id
}

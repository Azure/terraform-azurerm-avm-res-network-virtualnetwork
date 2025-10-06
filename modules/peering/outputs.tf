output "name" {
  description = "The name of the peering resource"
  value       = local.output_resource_name
}

output "peering_sync_status" {
  description = "The peering sync status of the peering resource."
  value       = local.output_peering_sync_status
}

output "resource_id" {
  description = "The resource ID of the peering resource."
  value       = local.output_resource_id
}

output "reverse_name" {
  description = "The name of the reverse peering resource"
  value       = local.output_reverse_resource_name
}

output "reverse_peering_sync_status" {
  description = "The peering sync status of the reverse peering resource."
  value       = local.output_reverse_peering_sync_status
}

output "reverse_resource_id" {
  description = "The resource ID of the reverse peering resource."
  value       = local.output_reverse_resource_id
}

output "address_spaces" {
  description = "The address spaces of the virtual network."
  value       = var.ipam_pools != null ? azapi_resource.vnet.output.properties.addressSpace.addressPrefixes : var.address_space
}

output "name" {
  description = "The resource name of the virtual network."
  value       = azapi_resource.vnet.name
}

output "peerings" {
  description = <<DESCRIPTION
Information about the peerings created in the module.

Please refer to the peering module documentation for details of the outputs
DESCRIPTION
  value       = module.peering
}

output "resource" {
  description = "Deprecated: The Azure Virtual Network resource. Use the discrete outputs instead."
  # TFFR2 is a SHOULD. Retain this legacy output until a planned breaking release
  # so existing consumers are not broken by the authoring-tool migration.
  # tflint-ignore: no_entire_resource_output_tffr2
  value = azapi_resource.vnet
}

output "resource_id" {
  description = "The resource ID of the virtual network."
  value       = azapi_resource.vnet.id
}

output "subnets" {
  description = <<DESCRIPTION
Information about the subnets created in the module.

Please refer to the subnet module documentation for details of the outputs
DESCRIPTION
  # All subnets now use the subnet module for consistent interface
  value = module.subnet
}

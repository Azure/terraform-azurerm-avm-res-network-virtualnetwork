output "address_prefixes" {
  value       = toset(data.azapi_resource.live_vnet.output.properties.addressSpace.addressPrefixes)
  description = "Address prefixes returned by a fresh GET after applying the VNet."
}

output "subnet_names" {
  value       = toset([for subnet in data.azapi_resource.live_vnet.output.properties.subnets : lower(element(reverse(split("/", subnet.id)), 0))])
  description = "Subnet names returned by a fresh GET after applying the VNet."
}

output "peering_names" {
  value       = toset([for peering in data.azapi_resource.live_vnet.output.properties.virtualNetworkPeerings : lower(element(reverse(split("/", peering.id)), 0))])
  description = "Peering names returned by a fresh GET after applying the VNet."
}

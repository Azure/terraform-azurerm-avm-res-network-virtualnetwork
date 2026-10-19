output "address_prefixes" {
  description = "Address prefixes returned by a fresh GET after applying the VNet."
  value       = toset(data.azapi_resource.live_vnet.output.properties.addressSpace.addressPrefixes)
}

output "subnet_names" {
  description = "Subnet names returned by a fresh GET after applying the VNet."
  value       = toset([for subnet in data.azapi_resource.live_vnet.output.properties.subnets : lower(element(reverse(split("/", subnet.id)), 0))])
}

output "peering_names" {
  description = "Peering names returned by a fresh GET after applying the VNet."
  value       = toset([for peering in data.azapi_resource.live_vnet.output.properties.virtualNetworkPeerings : lower(element(reverse(split("/", peering.id)), 0))])
}

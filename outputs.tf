output "id" {
  description = "The resource ID of the virtual network."
  value       = "/subscriptions/${local.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}"
}

output "resource" {
  description = "The Azure Virtual Network resource"
  value       = azapi_resource.vnet
}

output "subnets" {
  description = "Information about the subnets created in the module."
  value = {
    for s in azapi_resource.subnet : s.name => {
      id                 = s.id
      address_prefixes   = s.body.properties.addressPrefixes
      resource_group     = split("/", s.id)[4]
      virtual_network    = split("/", s.id)[8]
      nsg_association_id = s.body.properties.networkSecurityGroup
    }
  }
}

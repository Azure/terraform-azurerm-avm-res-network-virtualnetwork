output "name" {
  description = "The resource name of the virtual network."
  value       = try(azapi_resource.vnet[0].name, local.vnet_name)
}

output "resource" {
  description = "The Azure Virtual Network resource.  This will be null if an existing vnet is supplied."
  value       = try(azapi_resource.vnet[0], null)
}

output "resource_id" {
  description = "The resource ID of the virtual network."
  value       = try(azapi_resource.vnet[0].id, local.vnet_resource_id)
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

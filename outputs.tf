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
    for sk, sv in azapi_resource.subnet : sk => {
      # TODO should both id & resource_id be included?
      id                                               = sv.id
      resource_id                                      = sv.id
      address_prefixes                                 = sv.body.properties.addressPrefixes
      resource_group_name                              = split("/", sv.id)[4]
      virtual_network_name                             = split("/", sv.id)[8]
      nsg_resource_id                                  = try(sv.body.properties.networkSecurityGroup.id, null)
      route_table_resource_id                          = try(sv.body.properties.routeTable.id, null)
      nat_gateway_resource_id                          = try(sv.body.properties.natGateway.id, null)
      application_gateway_ip_configuration_resource_id = try(sv.body.properties.applicationGatewayIPConfigurations.id, null)
    }
  }
}

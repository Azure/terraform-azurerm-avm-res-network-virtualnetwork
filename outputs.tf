output "name" {
  description = "The resource name of the virtual network."
  value       = var.name
}

output "resource" {
  description = "The Azure Virtual Network resource.  This will be null if an existing vnet is supplied."
  value       = local.output_vnet_resource
}

output "resource_id" {
  description = "The resource ID of the virtual network."
  value       = local.vnet_resource_id
}

output "subnets" {
  description = <<DESCRIPTION
Information about the subnets created in the module.

- resource_id: The resource ID of the subnet.
- address_prefixes: The address prefixes of the subnet.
- resource_group_name: The resource group name of the subnet.
- virtual_network_name: The virtual network name of the subnet.
- nsg_resource_id: The network security group resource ID of the subnet.
- route_table_resource_id: The route table resource ID of the subnet.
- nat_gateway_resource_id: The NAT gateway resource ID of the subnet.
- application_gateway_ip_configuration_resource_id: The application gateway IP configuration resource ID of the subnet.

DESCRIPTION
  value = {
    for sk, sv in var.subnets : sk => {
      resource_id                                      = module.subnet[sk].resource_id
      address_prefixes                                 = sv.address_prefixes
      resource_group_name                              = var.resource_group_name
      virtual_network_name                             = var.name
      nsg_resource_id                                  = try(sv.network_security_group.id, null)
      route_table_resource_id                          = try(sv.route_table.id, null)
      nat_gateway_resource_id                          = try(sv.nat_gateway.id, null)
      application_gateway_ip_configuration_resource_id = module.subnet[sk].application_gateway_ip_configuration_resource_id
    }
  }
}

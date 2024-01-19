

output "subnets" {
  value = {
    for s in azurerm_subnet.subnet : s.name => {
      id               = s.id
      address_prefixes = s.address_prefixes
      resource_group   = s.resource_group_name
      virtual_network  = s.virtual_network_name

    }
  }
  description = "Information about the subnets created in the module."
}



output "vnet_resource" {
  value       = azurerm_virtual_network.vnet
  description = "The Azure Virtual Network resource"
}

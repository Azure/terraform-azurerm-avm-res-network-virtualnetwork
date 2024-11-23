data "azapi_resource" "vnet" {
  type                   = "Microsoft.Network/virtualNetworks@2024-03-01"
  name                   = azapi_resource.vnet.name
  parent_id              = azapi_resource.vnet.parent_id
  response_export_values = ["properties.addressSpace.addressPrefixes"]
}

locals {
  # for each subnet locate the ones which require dynamic allocation of IP addresses and calculate the bit offset
  subnet_newbits = { for key, value in var.subnets :
    key => try(value.address_prefix_size, 32) - try(split("/", jsondecode(data.azapi_resource.vnet.output).properties.addressSpace.addressPrefixes[0])[1], 0) if can(value.address_prefix_size)
  }
  #Generate the prefixes
  subnet_prefixes = cidrsubnets(jsondecode(data.azapi_resource.vnet.output).properties.addressSpace.addressPrefixes[0], values(local.subnet_newbits)...)
  subnets = { for key, value in var.subnets : key => merge(
    value,
    {
      address_prefix = contains(keys(local.subnet_newbits), key) ? element(local.subnet_prefixes, index(keys(local.subnet_newbits), key)) : value.address_prefix,
    }
  ) }
}

module "subnet" {
  source = "./modules/subnet"

  for_each = local.subnets

  virtual_network                               = { resource_id = azapi_resource.vnet.id }
  name                                          = each.value.name
  address_prefix                                = each.value.address_prefix
  address_prefixes                              = each.value.address_prefixes
  delegation                                    = each.value.delegation
  default_outbound_access_enabled               = each.value.default_outbound_access_enabled
  sharing_scope                                 = each.value.sharing_scope
  nat_gateway                                   = each.value.nat_gateway
  network_security_group                        = each.value.network_security_group
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  route_table                                   = each.value.route_table
  service_endpoints                             = each.value.service_endpoints
  service_endpoint_policies                     = each.value.service_endpoint_policies
  role_assignments                              = each.value.role_assignments
  subscription_id                               = local.subscription_id

  depends_on = [
    azapi_resource.vnet
  ]
}

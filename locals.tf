locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  # for each subnet locate the ones which require dynamic allocation of IP addresses and calculate the bit offset
  subnet_newbits = { for key, value in var.subnets :
    key => try(value.address_prefix_size, 32) - try(split("/", data.azapi_resource.vnet.output.properties.addressSpace.addressPrefixes[0])[1], 0) if value.address_prefix_size != null
  }
  #Generate the prefixes
  subnet_prefixes = cidrsubnets(data.azapi_resource.vnet.output.properties.addressSpace.addressPrefixes[0], values(local.subnet_newbits)...)
  subnets = { for key, value in var.subnets : key => merge(
    value,
    {
      address_prefix = contains(keys(local.subnet_newbits), key) ? element(local.subnet_prefixes, index(keys(local.subnet_newbits), key)) : value.address_prefix,
    }
  ) }
  subscription_id = coalesce(var.subscription_id, data.azurerm_client_config.this.subscription_id)
}

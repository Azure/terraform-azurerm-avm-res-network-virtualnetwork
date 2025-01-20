locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  # For each subnet locate the ones which require dynamic allocation of IP addresses and calculate the bit offset
  subnet_newbits = { for key, value in var.subnets :
    key => [
      for size in(value.address_prefix_sizes != null ? value.address_prefix_sizes : []) :
      size - split("/", data.azapi_resource.vnet.output.properties.addressSpace.addressPrefixes[0])[1]
    ]
    if length(value.address_prefix_sizes != null ? value.address_prefix_sizes : []) > 0
  }
  # Generate the prefixes if there is a more then one subnet with a length shorter then the address prefix
  subnet_prefixes = flatten(values(local.subnet_newbits)) == [0] ? [data.azapi_resource.vnet.output.properties.addressSpace.addressPrefixes[0]]: cidrsubnets(
    data.azapi_resource.vnet.output.properties.addressSpace.addressPrefixes[0],
    flatten(values(local.subnet_newbits))...
  )
  # Map the generated prefixes by key
  subnet_prefixes_by_key = { for key, value in local.subnet_newbits :
    key => slice(
      local.subnet_prefixes,
      index(keys(local.subnet_newbits), key),
      (index(keys(local.subnet_newbits), key) + length(var.subnets[key].address_prefix_sizes != null ? var.subnets[key].address_prefix_sizes : []))
    )
  }
  # Patch the dynamic prefixes into the subnet configuration
  subnets = { for key, value in var.subnets : key => merge(
    value,
    {
      address_prefix                    = contains(keys(local.subnet_newbits), key) ? null : value.address_prefix,
      address_prefixes                  = contains(keys(local.subnet_newbits), key) ? local.subnet_prefixes_by_key[key] : value.address_prefixes,
      multiple_address_prefixes_enabled = length(value.address_prefix_sizes != null ? value.address_prefix_sizes : []) > 1 ? true : false
    }
  ) }
  subscription_id = coalesce(var.subscription_id, data.azurerm_client_config.this.subscription_id)
}

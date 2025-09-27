data "azurerm_client_config" "current" {}

locals {
  # Calculate subnet address prefixes for traditional subnets with calculate_from_vnet = true
  calculated_subnets = {
    for k, v in var.subnets : k => merge(v, {
      # When calculating from VNet, use final_address_prefixes (list) and null out final_address_prefix
      # When not calculating, preserve original values
      final_address_prefix = (
        v.calculate_from_vnet == true &&
        v.prefix_length != null &&
        v.ipam_pools == null &&
        local.vnet_address_space != null
      ) ? null : v.address_prefix

      # Use calculated prefix (as list) when calculate_from_vnet=true, otherwise preserve original
      final_address_prefixes = (
        v.calculate_from_vnet == true &&
        v.prefix_length != null &&
        v.ipam_pools == null &&
        local.vnet_address_space != null
        ) ? [cidrsubnet(
          local.vnet_address_space,
          v.prefix_length - tonumber(split("/", local.vnet_address_space)[1]),
          v.subnet_index != null ? v.subnet_index : 0
      )] : v.address_prefixes
    })
    if v.ipam_pools == null # Only for traditional subnets
  }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  subscription_id                    = data.azurerm_client_config.current.subscription_id
  # For IPAM VNets, we need to use the allocated address space, not the input address_space
  # For traditional VNets, we use the input address_space
  vnet_address_space = var.ipam_pools != null ? (
    length(azapi_resource.vnet.output.properties.addressSpace.addressPrefixes) > 0 ?
    azapi_resource.vnet.output.properties.addressSpace.addressPrefixes[0] :
    null
    ) : (
    length(var.address_space) > 0 ? var.address_space[0] : null
  )
}

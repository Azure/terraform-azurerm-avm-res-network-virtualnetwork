data "azurerm_client_config" "current" {}

locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  subscription_id                    = data.azurerm_client_config.current.subscription_id
  # For IPAM VNets, we need to use the allocated address space, not the input address_space
  # For traditional VNets, we use the input address_space
  vnet_address_space = var.ipam_pools != null ? (
    length(azapi_resource.vnet.output.properties.addressSpace.addressPrefixes) > 0 ?
    azapi_resource.vnet.output.properties.addressSpace.addressPrefixes[0] :
    null
    ) : (
    length(var.address_space) > 0 ? tolist(var.address_space)[0] : null
  )
}

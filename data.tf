data "azurerm_client_config" "this" {}
# When creating a vnet with IPAM - The addressPrefixes is not returned on subsequent refreshes of the resource as it
# is not given when invoking the API. So we make a call to the API to get the addressPrefixes for use when creating the subnets.
data "azapi_resource" "vnet" {
  type      = "Microsoft.Network/virtualNetworks@2024-03-01"
  name      = azapi_resource.vnet.name
  parent_id = azapi_resource.vnet.parent_id
}
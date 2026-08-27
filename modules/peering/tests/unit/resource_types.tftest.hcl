mock_provider "azapi" {}

variables {
  name                      = "peer-resource-types-test"
  parent_id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/local-vnet"
  remote_virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/remote-vnet"
}

run "resource_type_override_is_applied" {
  command = plan

  variables {
    resource_types = {
      network_virtual_networks_virtual_network_peerings = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01"
    }
  }

  assert {
    condition     = azapi_resource.this[0].type == "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01"
    error_message = "The peering resource must use the resource_types override."
  }
}

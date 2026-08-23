mock_provider "azapi" {}

variables {
  name             = "snet-resource-types-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
  address_prefixes = ["10.0.0.0/24"]
}

run "resource_type_override_is_applied" {
  command = plan

  variables {
    resource_types = {
      network_virtual_networks_subnets = "Microsoft.Network/virtualNetworks/subnets@2023-11-01"
    }
  }

  assert {
    condition     = azapi_resource.subnet[0].type == "Microsoft.Network/virtualNetworks/subnets@2023-11-01"
    error_message = "The subnet resource must use the resource_types override."
  }
}

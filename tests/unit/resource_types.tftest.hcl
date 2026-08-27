mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  name             = "vnet-resource-types-test"
  location         = "westeurope"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
  enable_telemetry = false
  address_space    = ["10.0.0.0/16"]
}

run "resource_type_overrides_cascade_to_subnets" {
  command = plan

  variables {
    resource_types = {
      network_virtual_networks = "Microsoft.Network/virtualNetworks@2023-11-01"
      network_virtual_networks_subnets = {
        network_virtual_networks_subnets = "Microsoft.Network/virtualNetworks/subnets@2023-11-01"
      }
    }
    subnets = {
      test = {
        name             = "snet-resource-types-test"
        address_prefixes = ["10.0.0.0/24"]
      }
    }
  }

  assert {
    condition     = azapi_resource.vnet.type == "Microsoft.Network/virtualNetworks@2023-11-01"
    error_message = "The virtual network must use the root resource_types override."
  }

  assert {
    condition     = module.subnet["test"].resource.type == "Microsoft.Network/virtualNetworks/subnets@2023-11-01"
    error_message = "The subnet resource_types override must cascade through the root module."
  }
}

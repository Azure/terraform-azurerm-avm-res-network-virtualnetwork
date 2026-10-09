mock_provider "azapi" {
  mock_data "azapi_resource" {
    defaults = {
      exists = true
      output = {
        properties = {
          subnets = [
            {
              id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/vnet-unit-test/subnets/existing"
            }
          ]
          virtualNetworkPeerings = [
            {
              id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/vnet-unit-test/virtualNetworkPeerings/RemoteVnetToHubPeering_test"
            }
          ]
        }
      }
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  address_space    = ["10.0.0.0/16"]
  enable_telemetry = false
  location         = "westeurope"
  name             = "vnet-unit-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
}

run "new_vnet_has_no_imported_children" {
  command   = plan
  state_key = "new"

  override_data {
    target = data.azapi_resource.existing_vnet
    values = {
      exists = false
      output = null
    }
  }

  assert {
    condition     = !can(azapi_resource.vnet.body.properties.subnets) && !can(azapi_resource.vnet.body.properties.virtualNetworkPeerings)
    error_message = "A new VNet must not send imported child collections in its body."
  }
}

run "existing_vnet_with_only_subnets" {
  command   = plan
  state_key = "partial"

  override_data {
    target = data.azapi_resource.existing_vnet
    values = {
      exists = true
      output = {
        properties = {
          subnets = [
            {
              id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/vnet-unit-test/subnets/existing"
            }
          ]
        }
      }
    }
  }

  assert {
    condition     = length(azapi_resource.vnet.body.properties.subnets) == 1 && !can(azapi_resource.vnet.body.properties.virtualNetworkPeerings)
    error_message = "Only child collections returned by Azure should be sent in the VNet body."
  }
}

run "seed_imported_vnet_state" {
  command   = apply
  state_key = "imported"

  module {
    source = "./tests/unit/fixtures/imported_vnet_state"
  }
}

run "first_post_import_plan_preserves_child_collections" {
  command   = plan
  state_key = "imported"

  assert {
    condition     = length(azapi_resource.vnet.body.properties.subnets) == 1
    error_message = "The first post-import plan must preserve Azure-returned subnets."
  }

  assert {
    condition     = length(azapi_resource.vnet.body.properties.virtualNetworkPeerings) == 1
    error_message = "The first post-import plan must preserve Azure-returned virtual network peerings."
  }
}

run "address_space_change_preserves_imported_children" {
  command   = plan
  state_key = "imported"

  variables {
    address_space = ["10.0.0.0/15"]
  }

  assert {
    condition     = one(azapi_resource.vnet.body.properties.addressSpace.addressPrefixes) == "10.0.0.0/15"
    error_message = "Changing address_space after import must plan a VNet body update."
  }

  assert {
    condition     = length(azapi_resource.vnet.body.properties.subnets) == 1
    error_message = "Updating VNet address space must preserve imported subnets."
  }

  assert {
    condition     = length(azapi_resource.vnet.body.properties.virtualNetworkPeerings) == 1
    error_message = "Updating VNet address space must preserve imported virtual network peerings."
  }
}

run "apply_address_space_change_preserves_imported_children" {
  command   = apply
  state_key = "imported"

  variables {
    address_space = ["10.0.0.0/15"]
  }

  assert {
    condition     = one(azapi_resource.vnet.body.properties.addressSpace.addressPrefixes) == "10.0.0.0/15"
    error_message = "Applying address_space after import must update the VNet body."
  }

  assert {
    condition     = length(azapi_resource.vnet.body.properties.subnets) == 1 && length(azapi_resource.vnet.body.properties.virtualNetworkPeerings) == 1
    error_message = "Applying the address-space update must preserve imported subnets and peerings."
  }
}

run "unrelated_update_preserves_child_collections" {
  command   = apply
  state_key = "imported"

  variables {
    tags = {
      test = "updated-after-import"
    }
  }

  assert {
    condition     = length(azapi_resource.vnet.body.properties.subnets) == 1
    error_message = "Updating VNet tags after import must preserve Azure-returned subnets."
  }

  assert {
    condition     = length(azapi_resource.vnet.body.properties.virtualNetworkPeerings) == 1
    error_message = "Updating VNet tags after import must preserve Azure-returned virtual network peerings."
  }
}

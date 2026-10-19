mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "random" {}

variables {
  address_space    = ["10.0.0.0/16"]
  enable_telemetry = false
  location         = "westeurope"
  name             = "vnet-unit-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
}

run "new_vnet_omits_child_collections" {
  command   = plan
  state_key = "new"

  assert {
    condition     = !can(azapi_resource.vnet.body.properties.subnets) && !can(azapi_resource.vnet.body.properties.virtualNetworkPeerings)
    error_message = "A new VNet must omit child collections from the parent PUT."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "seed_imported_vnet_state" {
  command   = apply
  state_key = "imported"

  module {
    source = "./tests/unit/fixtures/imported_vnet_state"
  }
}

run "first_post_import_plan_omits_child_collections" {
  command   = plan
  state_key = "imported"

  assert {
    condition     = !can(azapi_resource.vnet.body.properties.subnets) && !can(azapi_resource.vnet.body.properties.virtualNetworkPeerings)
    error_message = "The VNet PUT must omit child collections even after import."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "address_space_change_after_import" {
  command   = plan
  state_key = "imported"

  variables {
    address_space = ["10.0.0.0/15"]
  }

  assert {
    condition     = one(azapi_resource.vnet.body.properties.addressSpace.addressPrefixes) == "10.0.0.0/15"
    error_message = "Changing address_space after import must plan an update to the VNet body."
  }

  assert {
    condition     = !can(azapi_resource.vnet.body.properties.subnets) && !can(azapi_resource.vnet.body.properties.virtualNetworkPeerings)
    error_message = "Changing address_space must not copy imported child collections into the VNet PUT."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "apply_address_space_change_after_import" {
  command   = apply
  state_key = "imported"

  variables {
    address_space = ["10.0.0.0/15"]
  }

  assert {
    condition     = one(azapi_resource.vnet.body.properties.addressSpace.addressPrefixes) == "10.0.0.0/15"
    error_message = "Applying address_space after import must update the VNet body."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

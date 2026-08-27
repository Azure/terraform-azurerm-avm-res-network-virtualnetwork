mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  address_space    = ["10.0.0.0/16"]
  enable_telemetry = false
  location         = "westeurope"
  name             = "vnet-unit-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
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

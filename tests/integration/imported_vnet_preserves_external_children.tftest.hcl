run "seed_vnet_outside_module" {
  command   = apply
  state_key = "seed"

  module {
    source = "./tests/integration/fixtures/imported_vnet_seed"
  }
}

run "preview_first_import_plan" {
  command   = plan
  state_key = "adopt"

  module {
    source = "./tests/integration/fixtures/imported_vnet_adopt"
  }

  variables {
    existing_vnet_id = run.seed_vnet_outside_module.vnet_id
    location         = run.seed_vnet_outside_module.location
    parent_id        = run.seed_vnet_outside_module.resource_group_id
  }

  assert {
    condition     = !can(module.vnet.resource.body.properties.subnets) && !can(module.vnet.resource.body.properties.virtualNetworkPeerings)
    error_message = "The first import plan must omit both child arrays from the configured parent PUT."
  }
}

run "apply_first_import_plan" {
  command   = apply
  state_key = "adopt"

  module {
    source = "./tests/integration/fixtures/imported_vnet_adopt"
  }

  variables {
    existing_vnet_id = run.seed_vnet_outside_module.vnet_id
    location         = run.seed_vnet_outside_module.location
    parent_id        = run.seed_vnet_outside_module.resource_group_id
  }

  assert {
    condition     = output.address_prefixes == toset(["10.70.0.0/15"])
    error_message = "The first apply after import must update the address space in Azure."
  }

  assert {
    condition     = output.subnet_names == toset(["external"]) && output.peering_names == toset(["external"])
    error_message = "The first apply after import must preserve the external subnet and peering."
  }
}

run "plan_again_after_import" {
  command   = plan
  state_key = "adopt"

  module {
    source = "./tests/integration/fixtures/imported_vnet_adopt"
  }

  variables {
    existing_vnet_id = run.seed_vnet_outside_module.vnet_id
    location         = run.seed_vnet_outside_module.location
    parent_id        = run.seed_vnet_outside_module.resource_group_id
  }

  assert {
    condition     = output.subnet_names == toset(["external"]) && output.peering_names == toset(["external"])
    error_message = "A subsequent plan must still see both subnets and the external peering."
  }
}

run "detach_imported_module_before_seed_cleanup" {
  command   = apply
  state_key = "adopt"

  module {
    source = "./tests/integration/fixtures/imported_vnet_detach"
  }
}

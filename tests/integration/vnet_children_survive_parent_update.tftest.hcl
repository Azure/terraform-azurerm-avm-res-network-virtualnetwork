run "create_vnet_with_managed_and_external_children" {
  command   = apply
  state_key = "vnet_children"

  module {
    source = "./tests/integration/fixtures/vnet_children_survive_parent_update"
  }

  variables {
    address_space = ["10.60.0.0/16"]
  }

  assert {
    condition     = output.address_prefixes == toset(["10.60.0.0/16"])
    error_message = "The initial VNet address space was not created."
  }

  assert {
    condition     = output.subnet_names == toset(["managed", "external"]) && output.peering_names == toset(["managed", "external"])
    error_message = "The initial VNet must contain both module-managed and external subnets and peerings."
  }
}

run "update_vnet_without_resending_children" {
  command   = apply
  state_key = "vnet_children"

  module {
    source = "./tests/integration/fixtures/vnet_children_survive_parent_update"
  }

  variables {
    address_space = ["10.60.0.0/15"]
  }

  assert {
    condition     = output.address_prefixes == toset(["10.60.0.0/15"])
    error_message = "The second parent PUT must update the Azure VNet address space."
  }

  assert {
    condition     = output.subnet_names == toset(["managed", "external"]) && output.peering_names == toset(["managed", "external"])
    error_message = "The second parent PUT must leave both managed and external subnets and peerings in Azure."
  }
}

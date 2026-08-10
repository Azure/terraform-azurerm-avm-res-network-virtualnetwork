# Unit tests for the subnet `ignore_body_changes` input validation.
# Runs at plan time with a mocked azapi provider - no Azure resources are
# deployed. Execute with: avm test unit
#
# Backs #61 / supersedes #70. `ignore_body_changes` maps to the write-only azapi
# argument that lets an out-of-band controller (AVNM routing / Azure Policy DINE)
# own a subnet property without perpetual drift. Entries must be body paths that
# start with `properties.`; a bare property name such as `routeTable` is silently
# ignored by the provider and would fail to suppress drift, so the module rejects
# it. These tests assert that guardrail.

mock_provider "azapi" {}

variables {
  name      = "subnet-unit-test"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
}

# A valid `properties.`-prefixed path must be accepted and must not strip the
# configured routeTable from the request body.
run "valid_properties_path_accepted" {
  command = plan

  variables {
    address_prefixes = ["10.0.0.0/24"]
    route_table = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/rt-test"
    }
    ignore_body_changes = ["properties.routeTable"]
  }

  assert {
    condition     = azapi_resource.subnet[0].body.properties.routeTable.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/rt-test"
    error_message = "routeTable must remain in the subnet body when ignore_body_changes is set."
  }
}

# An empty list is valid (nothing ignored).
run "empty_list_accepted" {
  command = plan

  variables {
    address_prefixes    = ["10.0.0.0/24"]
    ignore_body_changes = []
  }

  assert {
    condition     = length(var.ignore_body_changes) == 0
    error_message = "Empty ignore_body_changes must be accepted."
  }
}

# A bare property name (missing the `properties.` prefix) must be rejected -
# the provider would silently ignore it and drift would not be suppressed.
run "bare_property_name_rejected" {
  command = plan

  variables {
    address_prefixes    = ["10.0.0.0/24"]
    ignore_body_changes = ["routeTable"]
  }

  expect_failures = [
    var.ignore_body_changes,
  ]
}

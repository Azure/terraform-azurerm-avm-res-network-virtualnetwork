# Unit tests for the subnet `ignore_body_changes` input validation.
# Runs at plan time with a mocked azapi provider - no Azure resources are
# deployed. Execute with: avm test unit
#
# Backs #61 / supersedes #70. `ignore_body_changes` maps to the write-only azapi
# argument that lets an out-of-band controller (AVNM routing / Azure Policy DINE)
# own a subnet property without perpetual drift. Per AVM spec TFFR8 the variable
# is an object keyed by the resource type (`virtual_networks_subnets`); each
# entry must be a non-empty body path. These tests assert that guardrail.

mock_provider "azapi" {}

variables {
  name      = "subnet-unit-test"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
}

# A valid path must be accepted and must not strip the configured routeTable from
# the request body.
run "valid_path_accepted" {
  command = plan

  variables {
    address_prefixes = ["10.0.0.0/24"]
    route_table = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/rt-test"
    }
    ignore_body_changes = {
      virtual_networks_subnets = ["properties.routeTable"]
    }
  }

  assert {
    condition     = azapi_resource.subnet[0].body.properties.routeTable.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/rt-test"
    error_message = "routeTable must remain in the subnet body when ignore_body_changes is set."
  }
}

# The default empty object is valid (nothing ignored).
run "empty_object_accepted" {
  command = plan

  variables {
    address_prefixes    = ["10.0.0.0/24"]
    ignore_body_changes = {}
  }

  assert {
    condition     = length(var.ignore_body_changes.virtual_networks_subnets) == 0
    error_message = "Empty ignore_body_changes must be accepted and default the list to []."
  }
}

# A blank / whitespace-only entry must be rejected - the provider would silently
# ignore it and drift would not be suppressed.
run "blank_path_rejected" {
  command = plan

  variables {
    address_prefixes = ["10.0.0.0/24"]
    ignore_body_changes = {
      virtual_networks_subnets = ["   "]
    }
  }

  expect_failures = [
    var.ignore_body_changes,
  ]
}

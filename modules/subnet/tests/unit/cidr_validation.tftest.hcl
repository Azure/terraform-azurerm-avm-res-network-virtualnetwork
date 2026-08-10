# Unit tests for the subnet submodule CIDR-format validation on address_prefix
# and address_prefixes (#136). Runs at plan time with a mocked azapi provider.
# Execute with: avm test unit
#
# Direct submodule consumers must get the same guardrail as root-module callers:
# a structurally invalid CIDR is rejected at plan time rather than surfacing as
# an opaque Azure API error at apply.

mock_provider "azapi" {}

variables {
  name      = "subnet-unit-test"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
}

run "valid_address_prefix_accepted" {
  command = plan

  variables {
    address_prefix = "10.0.0.0/24"
  }
}

run "valid_address_prefixes_accepted" {
  command = plan

  variables {
    address_prefixes = ["10.0.0.0/24", "2001:db8::/64"]
  }
}

run "invalid_address_prefix_rejected" {
  command = plan

  variables {
    address_prefix = "totally bogus"
  }

  expect_failures = [var.address_prefix]
}

run "invalid_address_prefixes_rejected" {
  command = plan

  variables {
    address_prefixes = ["10..0.0.0/25"]
  }

  expect_failures = [var.address_prefixes]
}

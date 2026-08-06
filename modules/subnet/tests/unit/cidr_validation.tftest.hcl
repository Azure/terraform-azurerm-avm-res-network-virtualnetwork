mock_provider "azapi" {}

variables {
  name      = "subnet-unit-test"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
}

run "valid_ipv6_cidr" {
  command = plan

  variables {
    address_prefix = "2001:db8::/64"
  }
}

run "invalid_address_prefix" {
  command = plan

  variables {
    address_prefix = "totally bogus"
  }

  expect_failures = [var.address_prefix]
}

run "invalid_address_prefixes" {
  command = plan

  variables {
    address_prefixes = ["10..0.0.0/25", "10.0.0.0/99"]
  }

  expect_failures = [var.address_prefixes]
}

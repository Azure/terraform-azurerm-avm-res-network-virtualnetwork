mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  name             = "vnet-unit-test"
  location         = "westeurope"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
  enable_telemetry = false
}

run "valid_ipv4_and_ipv6_cidrs" {
  command = plan

  variables {
    address_space = ["10.0.0.0/16", "2001:db8::/48"]
    subnets = {
      ipv4 = {
        name             = "ipv4"
        address_prefixes = ["10.0.0.0/24"]
      }
      ipv6 = {
        name           = "ipv6"
        address_prefix = "2001:db8::/64"
      }
    }
  }
}

run "invalid_address_space_cidrs" {
  command = plan

  variables {
    address_space = ["10..0.0.0/25", "not-a-cidr", "10.0.0.0/99"]
  }

  expect_failures = [var.address_space]
}

run "invalid_subnet_address_prefix" {
  command = plan

  variables {
    address_space = ["10.0.0.0/16"]
    subnets = {
      invalid = {
        name           = "invalid"
        address_prefix = "totally bogus"
      }
    }
  }

  expect_failures = [var.subnets]
}

run "invalid_subnet_address_prefixes" {
  command = plan

  variables {
    address_space = ["10.0.0.0/16"]
    subnets = {
      invalid = {
        name             = "invalid"
        address_prefixes = ["10..0.0.0/25"]
      }
    }
  }

  expect_failures = [var.subnets]
}

run "invalid_peering_address_space" {
  command = plan

  variables {
    address_space = ["10.0.0.0/16"]
    peerings = {
      invalid = {
        name                               = "invalid"
        remote_virtual_network_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/remote-vnet"
        peer_complete_vnets                = false
        local_peered_address_spaces = [{
          address_prefix = "not-a-cidr"
        }]
        remote_peered_address_spaces = [{
          address_prefix = "10.1.0.0/16"
        }]
      }
    }
  }

  expect_failures = [var.peerings]
}

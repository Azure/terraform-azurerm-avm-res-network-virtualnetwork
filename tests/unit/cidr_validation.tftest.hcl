# Unit tests for CIDR-format validation on address_space, subnet address
# prefixes, and peering peered-address-space inputs (#136, also resolves #133).
# Runs at plan time with mocked providers - no Azure resources are deployed.
# Execute with: avm test unit
#
# Before this validation, structurally invalid CIDRs (double dots, missing
# slash, out-of-range prefix length) passed plan and only failed at apply with
# an opaque Azure API error. Each check uses `can(cidrhost(x, 0))`, which
# rejects malformed addresses, non-numeric prefixes, and out-of-range prefix
# lengths for both IPv4 and IPv6.

mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  name             = "vnet-unit-test"
  location         = "westeurope"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
  enable_telemetry = false
}

# --- Valid configurations (plan must succeed) ---

run "valid_ipv4_address_space_and_subnets" {
  command = plan

  variables {
    address_space = ["10.0.0.0/16"]
    subnets = {
      s1 = {
        name             = "s1"
        address_prefixes = ["10.0.1.0/24"]
      }
      s2 = {
        name           = "s2"
        address_prefix = "10.0.2.0/24"
      }
    }
  }
}

run "valid_ipv6_address_space" {
  command = plan

  variables {
    address_space = ["2001:db8::/48"]
    subnets = {
      s1 = {
        name             = "s1"
        address_prefixes = ["2001:db8:0:1::/64"]
      }
    }
  }
}

# --- Invalid configurations (validation must fail) ---

# Double dot in an address_space entry.
run "invalid_address_space_double_dot" {
  command = plan

  variables {
    address_space = ["10..0.0.0/25"]
  }

  expect_failures = [var.address_space]
}

# A value with no slash / not a CIDR at all.
run "invalid_address_space_not_a_cidr" {
  command = plan

  variables {
    address_space = ["not-a-cidr"]
  }

  expect_failures = [var.address_space]
}

# Out-of-range prefix length.
run "invalid_address_space_prefix_length" {
  command = plan

  variables {
    address_space = ["10.0.0.0/99"]
  }

  expect_failures = [var.address_space]
}

# Malformed subnet address_prefix (this is the #133 red herring).
run "invalid_subnet_address_prefix" {
  command = plan

  variables {
    address_space = ["10.0.0.0/16"]
    subnets = {
      s1 = {
        name           = "s1"
        address_prefix = "totally bogus"
      }
    }
  }

  expect_failures = [var.subnets]
}

# Malformed entry inside subnet address_prefixes.
run "invalid_subnet_address_prefixes" {
  command = plan

  variables {
    address_space = ["10.0.0.0/16"]
    subnets = {
      s1 = {
        name             = "s1"
        address_prefixes = ["10..0.0.0/25"]
      }
    }
  }

  expect_failures = [var.subnets]
}

# Malformed peering peered address space.
run "invalid_peering_address_prefix" {
  command = plan

  variables {
    address_space = ["10.0.0.0/16"]
    peerings = {
      p1 = {
        name                               = "peer1"
        remote_virtual_network_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/remote"
        peer_complete_vnets                = false
        local_peered_address_spaces = [{
          address_prefix = "10..0.0.0/25"
        }]
        remote_peered_address_spaces = [{
          address_prefix = "10.1.0.0/24"
        }]
      }
    }
  }

  expect_failures = [var.peerings]
}

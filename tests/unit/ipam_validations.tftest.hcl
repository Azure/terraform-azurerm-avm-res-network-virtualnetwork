# Unit tests for the root `ipam_pools` variable validations (SNFR4).
# Runs at plan time with mocked providers - no Azure resources are deployed.
# Execute with: ./avm tf-test-unit

mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  name             = "vnet-unit-test"
  location         = "westeurope"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
  enable_telemetry = false
}

# --- Valid configurations (plan must succeed) ---

run "valid_number_of_ip_addresses_only" {
  command = plan

  variables {
    ipam_pools = [{
      id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/test-pool"
      number_of_ip_addresses = "256"
    }]
  }
}

run "valid_prefix_length_only" {
  command = plan

  variables {
    ipam_pools = [{
      id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/test-pool"
      prefix_length = 24
    }]
  }
}

# Guards #65: dot is a valid character in an IPAM pool name.
run "valid_pool_id_with_dot" {
  command = plan

  variables {
    ipam_pools = [{
      id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/ipam-nm-10.197.0.0-16-shr"
      prefix_length = 24
    }]
  }
}

# One IPv4 + one IPv6 pool is the maximum allowed dual-stack configuration.
run "valid_one_ipv4_and_one_ipv6_pool" {
  command = plan

  variables {
    ipam_pools = [
      {
        id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/pool-v4"
        prefix_length = 24
      },
      {
        id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/pool-v6"
        prefix_length = 64
      }
    ]
  }
}

# --- Invalid configurations (validation must fail) ---

# A pool with neither number_of_ip_addresses nor prefix_length.
run "invalid_neither_field_set" {
  command = plan

  variables {
    ipam_pools = [{
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/test-pool"
    }]
  }

  expect_failures = [var.ipam_pools]
}

run "invalid_two_ipv4_pools" {
  command = plan

  variables {
    ipam_pools = [
      {
        id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/pool-a"
        prefix_length = 24
      },
      {
        id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/pool-b"
        prefix_length = 26
      }
    ]
  }

  expect_failures = [var.ipam_pools]
}

# Guards the IPv6 alignment fix: /56 must be classified as IPv6 (range 48-64),
# so two IPv6 pools are rejected. Before the fix, only /64 was counted and this
# would wrongly pass.
run "invalid_two_ipv6_pools" {
  command = plan

  variables {
    ipam_pools = [
      {
        id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/pool-v6a"
        prefix_length = 56
      },
      {
        id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/pool-v6b"
        prefix_length = 64
      }
    ]
  }

  expect_failures = [var.ipam_pools]
}

# More than two pools, isolated to the length rule by using number_of_ip_addresses
# only (so the per-family prefix_length checks do not also fire).
run "invalid_more_than_two_pools" {
  command = plan

  variables {
    ipam_pools = [
      {
        id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/pool-1"
        number_of_ip_addresses = "256"
      },
      {
        id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/pool-2"
        number_of_ip_addresses = "256"
      },
      {
        id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/pool-3"
        number_of_ip_addresses = "256"
      }
    ]
  }

  expect_failures = [var.ipam_pools]
}

run "invalid_pool_id_format" {
  command = plan

  variables {
    ipam_pools = [{
      id            = "not-a-valid-resource-id"
      prefix_length = 24
    }]
  }

  expect_failures = [var.ipam_pools]
}

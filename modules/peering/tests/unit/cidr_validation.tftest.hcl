# Unit tests for the peering submodule CIDR-format validation on the four
# peered-address-space inputs (#136). Runs the peering submodule as its own
# root at plan time with a mocked azapi provider - no Azure resources are
# deployed. Run locally with:
#   cd modules/peering && terraform test -test-directory ./tests/unit
#
# Direct submodule consumers must get the same guardrail as root-module callers:
# a structurally invalid CIDR in any peered address space is rejected at plan
# time rather than surfacing as an opaque Azure API error at apply.

mock_provider "azapi" {}

variables {
  name                      = "peer-hub-to-spoke"
  parent_id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub-vnet"
  remote_virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/spoke-rg/providers/Microsoft.Network/virtualNetworks/spoke-vnet"
}

run "valid_peered_address_spaces_accepted" {
  command = plan

  variables {
    peer_complete_vnets          = false
    local_peered_address_spaces  = [{ address_prefix = "10.0.0.0/24" }]
    remote_peered_address_spaces = [{ address_prefix = "2001:db8::/64" }]
  }
}

run "invalid_local_peered_address_space_rejected" {
  command = plan

  variables {
    peer_complete_vnets          = false
    local_peered_address_spaces  = [{ address_prefix = "10..0.0.0/25" }]
    remote_peered_address_spaces = [{ address_prefix = "10.1.0.0/24" }]
  }

  expect_failures = [var.local_peered_address_spaces]
}

run "invalid_remote_peered_address_space_rejected" {
  command = plan

  variables {
    peer_complete_vnets          = false
    local_peered_address_spaces  = [{ address_prefix = "10.0.0.0/24" }]
    remote_peered_address_spaces = [{ address_prefix = "not-a-cidr" }]
  }

  expect_failures = [var.remote_peered_address_spaces]
}

run "invalid_reverse_local_peered_address_space_rejected" {
  command = plan

  variables {
    create_reverse_peering               = true
    reverse_name                         = "peer-spoke-to-hub"
    reverse_peer_complete_vnets          = false
    reverse_local_peered_address_spaces  = [{ address_prefix = "10.0.0.0/99" }]
    reverse_remote_peered_address_spaces = [{ address_prefix = "10.2.0.0/24" }]
  }

  expect_failures = [var.reverse_local_peered_address_spaces]
}

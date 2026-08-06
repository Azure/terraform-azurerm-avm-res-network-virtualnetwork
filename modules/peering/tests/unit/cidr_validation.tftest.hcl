mock_provider "azapi" {}

variables {
  name                      = "peering-unit-test"
  parent_id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/local-vnet"
  remote_virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/remote-vnet"
}

run "valid_ipv6_cidrs" {
  command = plan

  variables {
    peer_complete_vnets         = false
    reverse_peer_complete_vnets = false
    create_reverse_peering      = true
    reverse_name                = "reverse"
    local_peered_address_spaces = [{
      address_prefix = "2001:db8::/64"
    }]
    remote_peered_address_spaces = [{
      address_prefix = "2001:db8:1::/64"
    }]
    reverse_local_peered_address_spaces = [{
      address_prefix = "2001:db8:1::/64"
    }]
    reverse_remote_peered_address_spaces = [{
      address_prefix = "2001:db8::/64"
    }]
  }
}

run "invalid_cidrs" {
  command = plan

  variables {
    local_peered_address_spaces = [{
      address_prefix = "10..0.0.0/25"
    }]
    remote_peered_address_spaces = [{
      address_prefix = "not-a-cidr"
    }]
    reverse_local_peered_address_spaces = [{
      address_prefix = "10.0.0.0/99"
    }]
    reverse_remote_peered_address_spaces = [{
      address_prefix = "totally bogus"
    }]
  }

  expect_failures = [
    var.local_peered_address_spaces,
    var.remote_peered_address_spaces,
    var.reverse_local_peered_address_spaces,
    var.reverse_remote_peered_address_spaces,
  ]
}

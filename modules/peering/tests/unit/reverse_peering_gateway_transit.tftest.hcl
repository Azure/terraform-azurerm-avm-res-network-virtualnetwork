# Regression guard for the #57 gateway-transit reverse-peering scenario.
# Runs the peering submodule (as its own root) at plan time with the mocked
# azapi provider - no Azure resources are deployed. Executed in CI by the AVM
# governance `tf-test-unit` target, which runs terraform test inside each
# modules/* directory. Run locally with:
#   cd modules/peering && terraform test -test-directory ./tests/unit
#
# Scope / honest limitation: `terraform test` cannot assert graph *ordering*.
# With a mocked provider both peering directions plan (and would apply)
# regardless of order, and the planned remoteVirtualNetwork.id value is
# identical whether main.tf references the forward resource
# (azapi_resource.this[0].parent_id) or the plain var.parent_id. So this test
# does not - and cannot - prove "reverse is created after forward"; that
# ordering is guaranteed by the resource reference documented in the NOTE(#57)
# comments in main.tf. This test instead locks in the #57 scenario wiring so a
# regression fails loudly at plan time: both directions must be created, the
# forward must carry allowGatewayTransit and the reverse useRemoteGateways, and
# the reverse must point back at the forward peering's virtual network.

mock_provider "azapi" {}

variables {
  name                      = "peer-hub-to-spoke"
  parent_id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub-vnet"
  remote_virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/spoke-rg/providers/Microsoft.Network/virtualNetworks/spoke-vnet"

  # Hub (forward) allows gateway transit; it does not consume remote gateways.
  peer_complete_vnets   = true
  allow_gateway_transit = true
  use_remote_gateways   = false

  # Spoke (reverse) consumes the hub's gateway; hub side does not re-advertise.
  create_reverse_peering        = true
  reverse_name                  = "peer-spoke-to-hub"
  reverse_peer_complete_vnets   = true
  reverse_allow_gateway_transit = false
  reverse_use_remote_gateways   = true
}

run "gateway_transit_reverse_peering_wiring" {
  command = plan

  # Both peering directions are created (full-vnet peering resources).
  assert {
    condition     = length(azapi_resource.this) == 1
    error_message = "Forward peering resource (azapi_resource.this) was not created"
  }
  assert {
    condition     = length(azapi_resource.reverse) == 1
    error_message = "Reverse peering resource (azapi_resource.reverse) was not created"
  }

  # The forward (hub -> spoke) peering enables gateway transit.
  assert {
    condition     = azapi_resource.this[0].body.properties.allowGatewayTransit == true
    error_message = "Forward peering must set allowGatewayTransit = true for the gateway-transit scenario"
  }

  # The reverse (spoke -> hub) peering consumes the hub's gateway.
  assert {
    condition     = azapi_resource.reverse[0].body.properties.useRemoteGateways == true
    error_message = "Reverse peering must set useRemoteGateways = true for the gateway-transit scenario"
  }

  # The reverse peering points back at the forward peering's virtual network.
  # This references azapi_resource.this[0].parent_id, the same expression that
  # creates the forward-before-reverse ordering edge (see the NOTE(#57) comment
  # in main.tf).
  assert {
    condition     = azapi_resource.reverse[0].body.properties.remoteVirtualNetwork.id == azapi_resource.this[0].parent_id
    error_message = "Reverse peering's remoteVirtualNetwork.id must resolve to the forward peering's VNet (parent_id)"
  }
}

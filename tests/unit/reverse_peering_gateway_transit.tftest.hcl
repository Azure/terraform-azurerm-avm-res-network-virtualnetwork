# Regression guard for the #57 gateway-transit reverse-peering scenario.
# Runs the root module (which calls modules/peering) at plan time with mocked
# providers - no Azure resources are deployed. Execute with: ./avm tf-test-unit
#
# Scope / honest limitation: `terraform test` cannot assert graph *ordering*.
# With a mocked provider both peering directions plan (and would apply)
# regardless of order, and the planned remoteVirtualNetwork.id value is
# identical whether main.tf references the forward resource
# (azapi_resource.this[0].parent_id) or the plain var.parent_id. So this test
# does not - and cannot - prove "reverse is created after forward"; that
# ordering is guaranteed by the resource reference documented in the NOTE(#57)
# comments in modules/peering/main.tf.
#
# What it does lock in is the #57 scenario wiring: with create_reverse_peering
# = true, allow_gateway_transit on the forward and use_remote_gateways on the
# reverse, the module must plan cleanly and produce BOTH a forward and a
# reverse peering. It fails loudly if that plumbing regresses (e.g. the reverse
# resource stops being created, or the gateway-transit inputs are rejected).

mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  name             = "vnet-hub"
  location         = "westeurope"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/hub-rg"
  address_space    = ["10.0.0.0/16"]
  enable_telemetry = false
}

run "gateway_transit_reverse_peering_plans_both_directions" {
  command = plan

  variables {
    peerings = {
      hub_to_spoke = {
        name                               = "peer-hub-to-spoke"
        remote_virtual_network_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/spoke-rg/providers/Microsoft.Network/virtualNetworks/spoke-vnet"

        # Hub (forward) allows gateway transit; it does not use remote gateways.
        allow_gateway_transit = true
        use_remote_gateways   = false

        # Spoke (reverse) uses the hub's gateway; hub side does not re-advertise.
        create_reverse_peering        = true
        reverse_name                  = "peer-spoke-to-hub"
        reverse_allow_gateway_transit = false
        reverse_use_remote_gateways   = true
      }
    }
  }

  # The forward (hub -> spoke) peering is planned.
  assert {
    condition     = output.peerings["hub_to_spoke"].name == "peer-hub-to-spoke"
    error_message = "Forward peering resource was not planned for the gateway-transit scenario"
  }

  # The reverse (spoke -> hub) peering is planned. reverse_name is non-null only
  # when create_reverse_peering produced a reverse resource, so this guards the
  # #57 reverse-peering feature against regressing to "no reverse created".
  assert {
    condition     = output.peerings["hub_to_spoke"].reverse_name == "peer-spoke-to-hub"
    error_message = "Reverse peering resource was not planned for the gateway-transit scenario"
  }
}

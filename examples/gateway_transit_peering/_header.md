# Example of hub-and-spoke Virtual Network peering with gateway transit

This code sample shows how to create a hub-and-spoke peering where the hub shares
its VPN gateway with the spoke. The hub → spoke peering sets
`allow_gateway_transit = true` and the spoke → hub reverse peering sets
`use_remote_gateways = true`.

Azure validates `use_remote_gateways` against the forward peering's
`allow_gateway_transit` at creation time, so the forward peering must be fully
provisioned before the reverse. This example is the topology from
[issue #57](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/issues/57).

> [!NOTE]
> This example deploys a real VPN gateway, which can take ~30 minutes to
> provision.

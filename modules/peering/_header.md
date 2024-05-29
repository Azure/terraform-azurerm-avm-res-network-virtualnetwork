# Azure Virtual Network Peering Module

This module is used to manage Azure Virtual Network Peerings.

## Features

This module supports managing virtual networks peerings.

The module supports:

- Creating a new peering
- Optionally creating a reverse peering

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Basic Subnet

This example shows the basic usage of the module. It creates a new bi-directional peering.

```terraform
module "avm-res-network-virtualnetwork-subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"

  virtual_network = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroupSpoke/providers/Microsoft.Network/virtualNetworks/myVNetLocal"
  }
  remote_virtual_network = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroupHub/providers/Microsoft.Network/virtualNetworks/myVNetRemote"
  }
  name                                 = "local-to-remote"
  allow_forwarded_traffic              = true
  allow_gateway_transit                = true
  allow_virtual_network_access         = true
  use_remote_gateways                  = false
  create_reverse_peering               = true
  reverse_name                         = "remote-to-local"
  reverse_allow_forwarded_traffic      = false
  reverse_allow_gateway_transit        = false
  reverse_allow_virtual_network_access = true
  reverse_use_remote_gateways          = false
}
```

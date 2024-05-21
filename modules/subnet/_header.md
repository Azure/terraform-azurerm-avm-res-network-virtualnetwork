# Azure Virtual Network Subnet Module

This module is used to manage Azure Virtual Network Subnets.

## Features

This module supports managing virtual networks and their associated subnets together or independently.

The module supports:

- Creating a new subnet

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Basic Subnet

This example shows the most basic usage of the module. It creates a new virtual network with no subnets.

```terraform
module "avm-res-network-virtualnetwork" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm/TBC???"

  address_prefixes    = ["10.0.0.0/24"]
  name                = "mySubnet"
  resource_group_name = "myResourceGroup"

}
```

### Example - Subnet with externally sourced Virtual Network

This example shows how to create subnets for a pre-exisating virtual network.

```terraform
module "avm-res-network-subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  existing_virtual_network = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet"
  }

  subnets = {
    "subnet1" = {
      name             = "subnet1"
      address_prefixes = ["10.0.0.0/24"]
    }
    "subnet2" = {
      name             = "subnet2"
      address_prefixes = ["10.0.1.0/24"]
    }
  }
}
```

# Azure Virtual Network Subnet Module

This module is used to manage Azure Virtual Network Subnets.

## Features

This module supports managing virtual networks and their associated subnets together or independently.

The module supports:

- Creating a new subnet
- Associating a network security group with a subnet
- Associating a route table with a subnet
- Associating a service endpoint with a subnet
- Associating a virtual network gateway with a subnet
- Assigning delegations to subnets

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Basic Subnet

This example shows the most basic usage of the module. It creates a new virtual network with no subnets.

```terraform
module "avm-res-network-virtualnetwork-subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  resource_group_name  = "myResourceGroup"
  virtual_network_name = "myVNet"
  name                 = "mySubnet"
  address_prefixes     = ["10.0.0.0/24"]
}
```

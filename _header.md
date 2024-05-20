# Azure Virtual Network Module

This module is used to manage Azure Virtual Networks, Subnets and Peerings.

## Features

This module supports managing virtual networks and their associated subnets together or independently. There is no separate AVM for subnets, this is also the subnet module.

The module supports:

- Creating a new virtual network
- Creating a new subnet
- Creating a new virtual network peering
- Associating DNS servers with a virtual network
- Associating a DDOS protection plan with a virtual network
- Associating a network security group with a subnet
- Associating a route table with a subnet
- Associating a service endpoint with a subnet
- Associating a virtual network gateway with a subnet
- Assigning delegations to subnets

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables. Here's a basic example:

```terraform
module "avm-res-network-virtualnetwork" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  address_spaces      = ["10.0.0.0/16"]
  location            = "East US"
  name                = "myVNet"
  resource_group_name = "myResourceGroup"
}
```

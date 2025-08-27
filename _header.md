# Azure Virtual Network Module

This module is used to manage Azure Virtual Networks, Subnets and Peerings.

This module is composite and includes sub modules that can be used independently for pre-existing virtual networks. These sub modules are:

- subnet - The subnet module is used to manage subnets within a virtual network.
- peering - The peering module is used to manage virtual network peerings.

## Features

This module supports managing virtual networks and their associated subnets and peerings together or independently.

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

## IPAM Support

This module supports IPAM (IP Address Management) pools for **virtual network address space allocation only**. IPAM pools are **not supported for individual subnets** due to technical limitations that can cause deployment failures.

**VNet IPAM Support:**
- Virtual networks can use IPAM pools for automatic address space allocation
- Use the `ipam_pools` variable to specify pool allocation for the VNet address space

**Subnet IPAM Limitations:**
- Subnets must use explicit `address_prefix` or `address_prefixes` values
- IPAM pool allocation for subnets can cause race conditions during concurrent deployments
- No mechanism exists to pre-allocate IP ranges in IPAM pools to prevent conflicts

**Important:** Subnets created with explicit IP addresses will appear as "Unallocated" in Azure Virtual Network Manager (AVNM) IPAM. This is expected behavior and indicates the subnet was not allocated through IPAM pools. Azure Portal and other Azure tools will still properly detect and prevent IP range conflicts.

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Virtual Network with Subnets

This example shows the most basic usage of the module. It creates a new virtual network with subnets.

```terraform
module "avm-res-network-virtualnetwork" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  address_space = ["10.0.0.0/16"]
  location      = "eastus2"
  name          = "vnet-demo-eastus2-001"
  parent_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo-eastus2-001"
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

### Example - Create a subnets on a pre-existing Virtual Network

This example shows how to create a subnet for a pre-existing virtual network using the subnet module.

```terraform
module "avm-res-network-subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  virtual_network = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet"
  }
  name             = "subnet1"
  address_prefixes = ["10.0.0.0/24"]
}
```

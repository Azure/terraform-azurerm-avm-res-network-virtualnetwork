# Azure Virtual Network Subnet Module

This module is used to manage Azure Virtual Network Subnets.

## Features

This module supports managing virtual networks subnets.

The module supports:

- Creating a new subnet
- Associating a network security group with a subnet
- Associating a route table with a subnet
- Associating a service endpoint with a subnet
- Associating a virtual network gateway with a subnet
- Assigning delegations to subnets

## IPAM Considerations

This module does not support IPAM (IP Address Management) pools for subnet address allocation. Subnets must be created with explicit `address_prefix` or `address_prefixes` values.

**Why IPAM pools are not supported for subnets:**
- IPAM pool allocation can cause race conditions when multiple subnets are created concurrently
- There's no mechanism to "pre-allocate" IP ranges in IPAM pools to prevent overlapping allocations
- Manual subnet creation with explicit IP ranges provides deterministic and reliable deployments

**Note:** Subnets created with explicit IP addresses will appear as "Unallocated" in Azure Virtual Network Manager (AVNM) IPAM. This is expected behavior and simply indicates the subnet was not allocated through IPAM pools. Azure Portal and other tools will still properly detect and avoid IP range conflicts with these manually allocated subnets.

For VNet-level IPAM pool usage, use the main virtual network module.

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Basic Subnet

This example shows the most basic usage of the module. It creates a new subnet.

```terraform
module "avm-res-network-virtualnetwork-subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  virtual_network = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet"
  }
  address_prefixes = ["10.0.0.0/24"]
}
```

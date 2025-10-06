# Azure Virtual Network Module

This module is used to manage Azure Virtual Networks, Subnets and Peerings, with optional IPAM (IP Address Management) support.

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
- **IPAM pool allocation for virtual network address space**
- **IPAM pool allocation for individual subnets**
- **Mixed IPAM and traditional addressing within the same virtual network**

## IPAM Support

This module provides comprehensive IPAM (IP Address Management) support through Azure Virtual Network Manager IPAM pools.

### What IPAM Provides
- **VNet address space allocation** from centralized IPAM pools
- **Subnet address allocation** from IPAM pools
- **Multiple pool support** for IPv4 and IPv6 addressing
- **Mixed addressing** - combine IPAM and traditional subnets in the same VNet
- **All standard subnet features** work with IPAM subnets (NSGs, service endpoints, delegations, etc.)

### Benefits
- **Centralized IP governance** through Azure Network Manager
- **Automatic conflict prevention** during address allocation
- **Simplified address management** across multiple deployments

### IPAM Regional Support

**⚠️ IPAM NOT supported in these regions:**
`austriaeast`, `chilecentral`, `chinaeast`, `chinanorth`, `indonesiacentral`, `malaysiawest`, `mexicocentral`, `newzealandnorth`, `spaincentral`

For the most up-to-date regional availability, consult the [Azure products by region](https://azure.microsoft.com/explore/global-infrastructure/products-by-region/) page.

### IPAM Examples
- **[ipam_basic](examples/ipam_basic/)** - Complete IPAM usage with VNet and multiple subnets
- **[existing_vnet_ipam_subnets](examples/existing_vnet_ipam_subnets/)** - Adding IPAM subnets to existing VNet managed by IPAM
- **[ipam_vnet_only](examples/ipam_vnet_only/)** - IPAM VNet creation without subnets

## Prerequisites

### For IPAM Features
- **Azure Virtual Network Manager**: Required for all IPAM functionality
- **Supported Azure region**: IPAM must be available in your target region (see [Regional Support](#ipam-regional-support))
- **azapi provider**: Version ~> 2.4 required for IPAM resource management
- **Proper permissions**: Network Manager and IPAM pool management permissions

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Basic Virtual Network with Subnets

This example shows the most basic usage of the module. It creates a new virtual network with subnets using traditional static addressing.

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

### Example - IPAM Virtual Network with Multiple Subnets

This example demonstrates IPAM usage with both VNet and subnet address allocation from IPAM pools.

```terraform
module "avm-res-network-virtualnetwork" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  location  = "East US"
  name      = "myIPAMVNet"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup"

  # VNet address space from IPAM pool
  ipam_pools = [{
    id            = azapi_resource.ipam_pool.id
    prefix_length = 24
  }]

  # Multiple subnets allocated from IPAM pool
  subnets = {
    "web_subnet" = {
      name = "subnet-web"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26
      }]
    }
    "app_subnet" = {
      name = "subnet-app"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26
      }]
    }
    "data_subnet" = {
      name = "subnet-data"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 27
      }]
    }
  }
}
```

### Example - Create a subnet on a pre-existing Virtual Network

This example shows how to create a subnet for a pre-existing virtual network using the subnet module.

```terraform
module "avm-res-network-subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet"
  name             = "subnet1"
  address_prefixes = ["10.0.0.0/24"]
}
```

## Troubleshooting

### Common IPAM Issues

- **"IPAM subnet creation failed"**: Ensure parent VNet was created with IPAM pools for its address space
- **"Region not supported"**: Check the [IPAM Regional Support](#ipam-regional-support) section above
- **"Network Manager not found"**: Ensure Azure Virtual Network Manager exists before creating IPAM pools
- **"Subnet overlap errors"**: Module uses retry logic to handle allocation conflicts automatically
- **"Pool exhausted"**: Check that your IPAM pool has sufficient available address space for the requested subnets
```

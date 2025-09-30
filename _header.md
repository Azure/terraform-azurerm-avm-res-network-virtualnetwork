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
- **IPAM pool allocation for individual subnets with conflict prevention**
- **Time-delayed sequential subnet creation for IPAM scenarios**
- **Mixed IPAM and traditional addressing within the same virtual network**

## IPAM Support

This module provides comprehensive support for Azure IPAM (IP Address Management) through Azure Virtual Network Manager IPAM pools.

### Virtual Network IPAM
- ✅ **Automatic address space allocation** from IPAM pools
- ✅ **Multiple pool support** (IPv4 and IPv6)
- ✅ **Flexible prefix length specification**

### Subnet IPAM
- ✅ **Individual subnet allocation** from IPAM pools
- ✅ **Time-delayed sequential creation** to prevent allocation conflicts (default: 30s delay)
- ✅ **Mixed addressing** - IPAM and traditional subnets in the same VNet
- ✅ **Configurable delay timing** between IPAM subnet allocations

### Key Benefits
- **Conflict Prevention**: Automatic time delays between IPAM subnet allocations prevent overlapping IP ranges
- **Centralized Management**: Leverage Azure Network Manager for IP address governance
- **Flexible Deployment**: Mix IPAM-allocated and statically-addressed subnets as needed
- **Production Ready**: Tested patterns for large-scale deployments

### IPAM Regional Support

**⚠️ IPAM NOT supported in these regions:**
`austriaeast`, `chilecentral`, `chinaeast`, `chinanorth`, `indonesiacentral`, `malaysiawest`, `mexicocentral`, `newzealandnorth`, `spaincentral`

For the most up-to-date regional availability, consult the [Azure products by region](https://azure.microsoft.com/explore/global-infrastructure/products-by-region/) page.

### IPAM Examples
- **[ipam_basic](examples/ipam_basic/)** - Getting started with basic VNet IPAM
- **[ipam_full](examples/ipam_full/)** - Complete IPAM deployment with all features
- **[ipam_vnet_only](examples/ipam_vnet_only/)** - IPAM for VNet address space with traditional subnets
- **[ipam_subnets](examples/ipam_subnets/)** - Time-delayed IPAM subnet creation
- **[existing_vnet_ipam_subnets](examples/existing_vnet_ipam_subnets/)** - Adding IPAM subnets to existing VNets managed by Azure Virtual Network Manager

**Important:** The module automatically handles IPAM allocation conflicts through time-delayed sequential creation. Subnets using IPAM pools are created with configurable delays (default 30 seconds) to ensure reliable deployments.

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

### Example - IPAM Virtual Network with Subnets

This example demonstrates IPAM usage with both VNet and subnet allocation from IPAM pools.

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

  # Subnets allocated from IPAM pool with automatic conflict prevention
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
- **"Subnet overlap errors"**: Module automatically prevents this with time delays between IPAM subnet creation
- **"Network Manager not found"**: Ensure Azure Virtual Network Manager exists before creating IPAM pools
- **"Deployment timeout"**: For many IPAM subnets, consider increasing `ipam_subnet_allocation_delay` parameter
```

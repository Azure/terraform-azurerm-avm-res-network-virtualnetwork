# Azure Virtual Network Subnet Module

This module is used to manage Azure Virtual Network Subnets.

## Features

This module supports managing virtual networks subnets with both traditional explicit addressing and IPAM (IP Address Management) dynamic allocation.

The module supports:

- Creating a new subnet with explicit IP addressing
- **Creating a new subnet with IPAM pool allocation**
- Associating a network security group with a subnet
- Associating a route table with a subnet
- Associating a service endpoint with a subnet
- Associating a virtual network gateway with a subnet
- Assigning delegations to subnets
- **Dynamic IP allocation from Azure Network Manager IPAM pools**

## IPAM Support

This subnet module now provides comprehensive IPAM (IP Address Management) support for dynamic subnet allocation alongside traditional explicit addressing.

### ⚠️ **CRITICAL REQUIREMENT: IPAM-Enabled Virtual Networks**

**IPAM subnets can ONLY be created within IPAM-enabled Virtual Networks.**

- ✅ **IPAM VNet + IPAM Subnet** = ✅ **SUPPORTED**
- ✅ **IPAM VNet + Traditional Subnet** = ✅ **SUPPORTED** (mixed architecture)
- ❌ **Traditional VNet + IPAM Subnet** = ❌ **NOT POSSIBLE**

If the parent Virtual Network was not created with IPAM pools for its address space, you cannot create IPAM subnets within it. The VNet must be IPAM-enabled first.

### **IPAM Features:**
- **Dynamic subnet allocation** from IPAM pools with automatic conflict prevention
- **Automatic IP address assignment** with specified prefix lengths
- **Consistent interface** with main VNet module IPAM capabilities
- **Comprehensive retry logic** for reliable Azure API interactions
- **All standard subnet features** work with IPAM (NSGs, route tables, service endpoints, delegations)

### **Usage Patterns:**
- **Traditional addressing**: Specify `address_prefix` or `address_prefixes`
- **IPAM allocation**: Specify `ipam_pools` with pool ID and prefix length
- **Cannot mix**: Use either traditional OR IPAM addressing per subnet (not both)
- **Mixed VNets**: Within an IPAM-enabled VNet, you can have both IPAM and traditional subnets

### **Key Benefits:**
- **Individual subnet management**: Add IPAM subnets to existing IPAM VNets independently
- **Flexible deployment**: Choose addressing method per subnet as needed within IPAM VNets
- **Production ready**: Same robust retry logic as main module IPAM implementation
- **Consistent experience**: IPAM works the same way across main and subnet modules
- **Automatic conflict prevention** - no overlapping IP assignments
- **Dynamic allocation** - specify size requirements, get IP ranges automatically
- **Consistent with main module** - same IPAM capabilities as the VNet module

**Important Notes:**
- **Choose one addressing method**: Cannot mix IPAM and traditional addressing in same subnet
- **Pool requirement**: IPAM pools must be created through Azure Network Manager first
- **Single pool limit**: Each subnet can allocate from only one IPAM pool currently
- **Prefix length**: Specify the desired subnet size (e.g., 24 for /24, 26 for /26)

**IPAM vs Traditional:**
- **IPAM subnets**: Show allocated ranges in Azure Network Manager IPAM dashboard
- **Traditional subnets**: Appear as "Unallocated" in IPAM (expected behavior)
- **Both types**: Fully supported by Azure networking and portal tools

For comprehensive multi-subnet IPAM scenarios with time-delayed sequential creation, use the main virtual network module with multiple IPAM subnets.

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Basic Subnet

This example shows the most basic usage of the module. It creates a new subnet with explicit addressing.

```terraform
module "avm-res-network-virtualnetwork-subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  name             = "subnet-web"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet"
  address_prefixes = ["10.0.0.0/24"]
}
```

### Example - IPAM Subnet

This example demonstrates IPAM usage for dynamic subnet allocation.

```terraform
module "avm-res-network-virtualnetwork-subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  name      = "subnet-app"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet"

  # Dynamic allocation from IPAM pool
  ipam_pools = [{
    pool_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/networkManagers/myNetworkManager/ipamPools/myPool"
    prefix_length = 26  # Allocate a /26 subnet (64 IP addresses)
  }]

  # Standard subnet features work with IPAM
  network_security_group = {
    id = azurerm_network_security_group.app.id
  }
  service_endpoints = ["Microsoft.Storage"]
}
```

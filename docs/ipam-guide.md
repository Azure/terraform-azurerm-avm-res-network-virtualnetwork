# Azure IPAM Integration Guide

This guide provides comprehensive information on using Azure IPAM (IP Address Management) with the AVM Virtual Network module.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [VNet IPAM Configuration](#vnet-ipam-configuration)
- [Subnet IPAM Configuration](#subnet-ipam-configuration)
- [Using Subnet Submodule with IPAM](#using-subnet-submodule-with-ipam)
- [Mixed Scenarios](#mixed-scenarios)
- [Troubleshooting](#troubleshooting)

## Overview

Azure IPAM provides centralized IP address space management through Network Managers and IPAM pools. The AVM Virtual Network module supports IPAM for:

- ✅ **Virtual Network address space allocation**
- ✅ **Subnet address allocation with conflict prevention**
- ✅ **Mixed IPAM and traditional addressing**
- ✅ **Independent subnet submodule usage**

## Prerequisites

Before using IPAM with this module, ensure you have:

1. **Network Manager** with appropriate scope (subscription/management group)
2. **IPAM Pool** with available address space
3. **Appropriate Azure permissions** for Network Manager and IPAM operations

### Setting Up IPAM Infrastructure

```hcl
# Network Manager
resource "azapi_resource" "network_manager" {
  type      = "Microsoft.Network/networkManagers@2024-07-01"
  parent_id = azurerm_resource_group.this.id
  name      = "avnm-ipam"
  location  = azurerm_resource_group.this.location

  body = {
    properties = {
      networkManagerScopes = {
        subscriptions = [data.azurerm_subscription.this.id]
      }
      networkManagerScopeAccesses = []
    }
  }
}

# IPAM Pool
resource "azapi_resource" "ipam_pool" {
  type      = "Microsoft.Network/networkManagers/ipamPools@2024-07-01"
  parent_id = azapi_resource.network_manager.id
  name      = "ipam-pool-main"

  body = {
    properties = {
      addressPrefixes = ["10.0.0.0/16"]
      description     = "Main IPAM pool for organization"
      displayName     = "Organization IP Pool"
    }
  }
}
```

## VNet IPAM Configuration

### Basic VNet with IPAM Address Space

```hcl
module "vnet_ipam" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  location            = "East US 2"
  resource_group_name = "rg-networking"
  name                = "vnet-ipam-example"

  # VNet gets address space from IPAM pool
  ipam_pools = [{
    id            = azapi_resource.ipam_pool.id
    prefix_length = 24  # Request /24 from pool
  }]

  # Optional: Traditional subnets can still be used
  subnets = {
    management = {
      name             = "subnet-management"
      address_prefixes = ["10.0.0.0/27"]  # Static addressing
    }
  }
}
```

### Multiple IPAM Pools (IPv4 + IPv6)

```hcl
module "vnet_dual_stack" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  # ... basic config ...

  ipam_pools = [
    {
      id            = azapi_resource.ipv4_pool.id
      prefix_length = 24
    },
    {
      id            = azapi_resource.ipv6_pool.id
      prefix_length = 56
    }
  ]
}
```

## Subnet IPAM Configuration

### Time-Delayed Sequential IPAM Subnets

The module prevents IPAM allocation conflicts through time-delayed sequential creation:

```hcl
module "vnet_with_ipam_subnets" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  # ... basic config ...

  # VNet uses IPAM
  ipam_pools = [{
    id            = azapi_resource.ipam_pool.id
    prefix_length = 24
  }]

  # Configure delay between IPAM subnet allocations
  ipam_subnet_allocation_delay = 45  # 45 seconds between subnets

  subnets = {
    # These will be created sequentially to prevent conflicts
    web = {
      name = "subnet-web"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26  # /26 from parent VNet's /24
      }]
    }

    app = {
      name = "subnet-app"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26  # Created 45s after web subnet
      }]
    }

    data = {
      name = "subnet-data"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 27  # Created 90s after web subnet
      }]
    }
  }
}
```

### IPAM Allocation Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `pool_id` | Resource ID of IPAM pool | `/subscriptions/.../ipamPools/my-pool` |
| `prefix_length` | CIDR prefix length to request | `26` (for /26 subnet) |
| `allocation_type` | Allocation method | `"Static"` (default) or `"Dynamic"` |

### Sequential Creation Timeline

For 3 IPAM subnets with 45s delay:

```
t=0s:  VNet created
t=0s:  subnet-web starts creation
t=45s: subnet-app starts creation
t=90s: subnet-data starts creation
```

## Using Subnet Submodule with IPAM

### Adding Subnets to Existing IPAM VNet

You can use the subnet submodule independently to add subnets to existing IPAM-managed VNets:

```hcl
# Add traditional subnet to existing IPAM VNet
module "additional_subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  name            = "subnet-additional"
  virtual_network = {
    resource_id = "/subscriptions/.../virtualNetworks/existing-ipam-vnet"
  }

  # Use static addressing (no IPAM conflicts)
  address_prefix = "10.0.1.0/24"

  # Standard subnet configuration
  network_security_group = {
    id = azurerm_network_security_group.example.id
  }
}
```

### Calculated Subnets from IPAM VNet

```hcl
# Calculate subnet address from IPAM-allocated VNet address space
module "calculated_subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  name            = "subnet-calculated"
  virtual_network = {
    resource_id = module.ipam_vnet.resource_id
  }

  # Calculate from VNet's address space (works with IPAM VNets)
  calculate_from_vnet = true
  prefix_length       = 26
  subnet_index        = 0  # First /26 in VNet's address space
}
```

### Important Notes for Subnet Submodule

- **No IPAM support in submodule**: The standalone subnet module does not support IPAM pools
- **Use static addressing**: Specify explicit `address_prefix` or `address_prefixes`
- **Calculate from VNet**: Use `calculate_from_vnet = true` to derive from existing VNet space
- **Avoid conflicts**: Ensure subnet addresses don't overlap with IPAM-allocated subnets

## Mixed Scenarios

### IPAM VNet with Mixed Subnet Types

```hcl
module "mixed_vnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  # VNet uses IPAM
  ipam_pools = [{
    id            = azapi_resource.ipam_pool.id
    prefix_length = 24
  }]

  ipam_subnet_allocation_delay = 45

  subnets = {
    # IPAM subnet (sequential creation)
    web = {
      name = "subnet-web"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26
      }]
    }

    # Another IPAM subnet (delayed 45s)
    app = {
      name = "subnet-app"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26
      }]
    }

    # Static subnet (immediate creation)
    management = {
      name             = "subnet-management"
      address_prefixes = ["10.0.0.192/26"]
    }

    # Calculated subnet (immediate creation)
    services = {
      name                = "subnet-services"
      calculate_from_vnet = true
      prefix_length       = 28
      subnet_index        = 0
    }
  }
}
```

### Existing VNet with New IPAM Subnets

```hcl
# Add IPAM subnets to traditional VNet (not recommended)
module "existing_vnet_ipam_subnets" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  # Reference existing VNet
  existing_vnet_resource_id = "/subscriptions/.../virtualNetworks/existing-vnet"

  # Add IPAM subnets
  subnets = {
    new_ipam_subnet = {
      name = "subnet-new-ipam"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26
      }]
    }
  }
}
```

**⚠️ Warning**: Adding IPAM subnets to non-IPAM VNets may cause conflicts. Best practice is to use IPAM from the start or stick with traditional addressing.

## Troubleshooting

### Common Issues and Solutions

#### 1. NetcfgSubnetRangesOverlap Error

**Error:**
```
NetcfgSubnetRangesOverlap - Subnet overlaps with existing subnet
```

**Causes:**
- Multiple IPAM subnets created simultaneously
- Insufficient delay between IPAM subnet creations

**Solutions:**
```hcl
# Increase delay between IPAM subnet creations
ipam_subnet_allocation_delay = 60  # Increase from 45 to 60 seconds

# Ensure only IPAM subnets reference IPAM pools
subnets = {
  ipam_subnet = {
    ipam_pools = [{ pool_id = "...", prefix_length = 26 }]
    # Do NOT also specify address_prefix or address_prefixes
  }
}
```

#### 2. VNet Address Space Mismatch

**Error:**
```
VNet prefixes are not in scope of pool
```

**Causes:**
- VNet has static address space that doesn't match IPAM pool
- Trying to add IPAM subnets to non-IPAM VNet

**Solutions:**
```hcl
# Ensure VNet uses IPAM for address space
ipam_pools = [{
  id            = azapi_resource.ipam_pool.id
  prefix_length = 24
}]

# Do NOT specify address_space when using ipam_pools
# address_space = ["10.0.0.0/24"]  # Remove this
```

#### 3. Subnet Outside VNet Range

**Error:**
```
Subnet IP address range is outside the VNet range
```

**Causes:**
- Static subnet address doesn't fit in IPAM-allocated VNet space
- Calculated subnet parameters incorrect

**Solutions:**
```hcl
# For static subnets in IPAM VNet, use calculated addressing
subnets = {
  management = {
    name                = "subnet-management"
    calculate_from_vnet = true  # Calculate from IPAM-allocated space
    prefix_length       = 27
    subnet_index        = 0
    # Don't use: address_prefixes = ["10.0.0.0/27"]
  }
}
```

#### 4. Pool Allocation Failures

**Error:**
```
IPAM API call failed with status BadRequest
```

**Causes:**
- IPAM pool exhausted
- Insufficient permissions
- Pool not properly configured

**Solutions:**
```hcl
# Check pool has available space
data "azapi_resource" "ipam_pool_check" {
  type        = "Microsoft.Network/networkManagers/ipamPools@2024-07-01"
  resource_id = azapi_resource.ipam_pool.id
}

output "pool_status" {
  value = data.azapi_resource.ipam_pool_check.output
}

# Ensure proper permissions on Network Manager
resource "azurerm_role_assignment" "ipam_contributor" {
  scope                = azapi_resource.network_manager.id
  role_definition_name = "Network Manager Contributor"
  principal_id         = data.azurerm_client_config.this.object_id
}
```

### Performance Tuning

#### Delay Recommendations by Scale

| Scenario | Subnets | Recommended Delay | Total Time |
|----------|---------|------------------|------------|
| Small    | 2-3     | 30s             | ~1min      |
| Medium   | 4-6     | 45s             | ~3min      |
| Large    | 7-10    | 60s             | ~8min      |
| XLarge   | 10+     | 90s             | ~15min+    |

#### Regional Considerations

| Region Type | Recommended Delay |
|-------------|------------------|
| Primary (East US, West Europe) | 30-45s |
| Secondary (West US 2, North Europe) | 45s |
| Emerging (Southeast Asia, Brazil) | 60s+ |

### Monitoring and Validation

#### Check IPAM Allocation Results

```hcl
# Output actual allocated addresses
output "vnet_address_space" {
  value = module.vnet_ipam.resource.properties.addressSpace
}

output "subnet_addresses" {
  value = {
    for key, subnet in module.vnet_ipam.subnets : key => subnet.resource.properties.addressPrefix
  }
}
```

#### Validate Non-Overlapping Allocations

```bash
# After successful deployment
terraform output vnet_address_space
terraform output subnet_addresses

# Check for overlaps (should return empty)
terraform state show 'module.vnet_ipam.azapi_resource.ipam_subnet["web"]' | grep addressPrefix
terraform state show 'module.vnet_ipam.azapi_resource.ipam_subnet["app"]' | grep addressPrefix
```

This guide provides comprehensive coverage of IPAM usage patterns with the AVM Virtual Network module. For additional examples and advanced scenarios, see the [examples directory](../examples/ipam_timed_subnets/).

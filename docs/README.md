# Azure Virtual Network Module Documentation

This directory contains detailed documentation for the Azure Virtual Network (AVM) module.

## Documentation Structure

### Core Module Documentation
- **[README.md](../README.md)** - Main module documentation with API reference, variables, and outputs
- **[Examples](../examples/)** - Practical usage examples for different scenarios

### Detailed Guides
- **[Comprehensive Guide](comprehensive-guide.md)** - Complete module capabilities and usage patterns
- **[IPAM Examples](../examples/)** - Specific IPAM scenarios:
  - **[ipam_basic](../examples/ipam_basic/)** - Getting started with VNet IPAM
  - **[ipam_full](../examples/ipam_full/)** - Comprehensive IPAM deployment with all features
  - **[ipam_vnet_only](../examples/ipam_vnet_only/)** - IPAM for VNet with traditional subnets
  - **[ipam_mixed](../examples/ipam_mixed/)** - Hybrid IPAM and traditional addressing
  - **[ipam_subnets](../examples/ipam_subnets/)** - Time-delayed IPAM subnet creation

### Submodule Documentation
- **[Subnet Module](../modules/subnet/README.md)** - Standalone subnet management
- **[Peering Module](../modules/peering/README.md)** - Virtual network peering

## Quick Navigation

### By Feature
| Feature | Documentation | Examples |
|---------|---------------|----------|
| **Basic VNet** | [README](../README.md#usage) | [default](../examples/default/) |
| **IPAM VNet** | [README](../README.md#ipam-support) | [ipam_basic](../examples/ipam_basic/) |
| **IPAM Subnets** | [README](../README.md#ipam-support) | [ipam_full](../examples/ipam_full/), [ipam_subnets](../examples/ipam_subnets/) |
| **Mixed Addressing** | [Comprehensive Guide](comprehensive-guide.md) | [ipam_mixed](../examples/ipam_mixed/) |
| **VNet Peering** | [README](../README.md) | [existing_vnet_peering](../examples/existing_vnet_peering/) |
| **Subnet Management** | [Subnet Module](../modules/subnet/README.md) | [existing_vnet_subnets](../examples/existing_vnet_subnets/) |

### By Use Case
| Use Case | Primary Documentation | Recommended Example |
|----------|----------------------|-------------------|
| **Getting Started** | [README](../README.md#usage) | [default](../examples/default/) |
| **IPAM Introduction** | [README](../README.md#ipam-support) | [ipam_basic](../examples/ipam_basic/) |
| **Enterprise IPAM** | [Comprehensive Guide](comprehensive-guide.md) | [ipam_full](../examples/ipam_full/) |
| **Migration Scenarios** | [Comprehensive Guide](comprehensive-guide.md) | [ipam_mixed](../examples/ipam_mixed/) |
| **Existing VNet Extension** | [Subnet Module](../modules/subnet/README.md) | [existing_vnet_subnets](../examples/existing_vnet_subnets/) |

## IPAM Quick Reference

### Time-Delayed Sequential Creation
IPAM subnets are created with automatic delays to prevent allocation conflicts:
```
t=0s:   First IPAM subnet starts
t=30s:  Second IPAM subnet starts (default delay)
t=60s:  Third IPAM subnet starts
```

### Configuration Parameters
- **`ipam_subnet_allocation_delay`** - Delay between IPAM subnet creations (default: 30 seconds)
- **`ipam_pools`** - IPAM pool allocation for VNet address space
- **`subnets[].ipam_pools`** - IPAM pool allocation for individual subnets

### Regional Availability
IPAM is available in these Azure regions:
- East US 2, West US 2, West Europe
- Additional regions being added regularly

## Support and Contribution

- **Issues**: [GitHub Issues](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/issues)
- **Contributing**: [CONTRIBUTING.md](../CONTRIBUTING.md)
- **Security**: [SECURITY.md](../SECURITY.md)

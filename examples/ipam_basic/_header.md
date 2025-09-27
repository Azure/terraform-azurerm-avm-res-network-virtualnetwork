# IPAM Basic Example

This example demonstrates the simplest use case for IPAM: VNet address space allocation from IPAM pools with traditional static subnets.

## Features Demonstrated

- ✅ **Basic VNet IPAM** - IPv4 and IPv6 address space from IPAM pools
- ✅ **Dual-stack support** - Both IPv4 and IPv6 allocation in single deployment
- ✅ **Static subnet addressing** - Traditional subnet management within IPAM VNet
- ✅ **Standard network features** - NSGs, service endpoints work normally

## Use Case

Perfect for:
- **Getting started with IPAM** - Simple introduction to IPAM concepts
- **Dual-stack networking** - Testing IPv4 and IPv6 together
- **Hybrid addressing** - IPAM VNet with familiar subnet management
- **Learning and development** - Understanding IPAM fundamentals

## Architecture

```
IPv4 Pool (10.0.0.0/16) → VNet (/24 allocated)
IPv6 Pool (fdea:5251:1c0a::/48) → VNet (/63 allocated)
│
└── VNet (dual-stack with IPAM allocation)
    ├── subnet1 (10.0.0.0/25) - static addressing
    └── subnet2 (10.0.0.128/25) - static addressing
```

## Key Learning Points

1. **IPAM Pool Setup** - Network Manager and pool configuration
2. **Dual-Stack Allocation** - Requesting both IPv4 and IPv6 space
3. **Static Subnet Compatibility** - Using traditional addressing within IPAM VNets
4. **Regional Availability** - IPAM is available in limited Azure regions

This is the recommended starting point for understanding IPAM capabilities before moving to more advanced scenarios.

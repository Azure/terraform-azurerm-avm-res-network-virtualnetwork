# IPAM Basic Example

This example demonstrates comprehensive IPAM usage with both VNet and subnet address allocation from IPAM pools, featuring automatic conflict resolution through enhanced retry logic.

## Features Demonstrated

- ✅ **IPAM VNet Address Allocation** - VNet gets address space from IPAM pool
- ✅ **IPAM Subnet Allocation** - Multiple subnets get space from the same pool
- ✅ **Automatic Conflict Resolution** - Enhanced retry logic handles allocation conflicts
- ✅ **No Time Delays** - Uses retry-only approach instead of artificial delays
- ✅ **Simultaneous Creation** - All subnets created in parallel without timing issues

## Use Case

Perfect for:
- **Getting started with IPAM** - Complete introduction to IPAM concepts
- **Production deployments** - Reliable conflict resolution without delays
- **Multiple subnet scenarios** - Creating several subnets from same pool
- **Learning modern patterns** - Understanding retry-based conflict resolution

## Architecture

```
IPAM Pool (10.0.0.0/16)
│
├── VNet (/24 allocated dynamically)
│   ├── subnet1-retry-test (64 IPs from pool)
│   ├── subnet2-retry-test (64 IPs from pool)
│   ├── subnet3-retry-test (32 IPs from pool)
│   └── subnet4-retry-test (32 IPs from pool)
```

## Conflict Resolution

This example demonstrates the **modern approach** to IPAM subnet allocation:

- **Enhanced Retry Logic** - Automatically handles allocation conflicts
- **Error Pattern Matching** - Detects overlap and conflict errors
- **No Artificial Delays** - Relies on Azure API retry mechanisms
- **Parallel Creation** - All resources created simultaneously

## Key Learning Points

1. **IPAM Pool Setup** - Network Manager and pool configuration
2. **Retry-Based Conflict Resolution** - Modern alternative to time delays
3. **Simultaneous Resource Creation** - Efficient parallel deployment
4. **Error Handling Patterns** - Understanding IPAM conflict scenarios

This is the recommended starting point for understanding comprehensive IPAM capabilities with production-ready patterns.

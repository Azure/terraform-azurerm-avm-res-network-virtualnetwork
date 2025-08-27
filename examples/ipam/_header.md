# Simple example for the Azure Virtual Network module with IPAM support

This example demonstrates how to create and manage Azure Virtual Networks (vNets) using IPAM for address space allocation.

**Important:** IPAM pools are only supported for virtual network address spaces, not for individual subnets. Subnets must be created with explicit IP address ranges.

**Why subnets don't support IPAM pools:**
- Concurrent subnet creation can cause race conditions with IPAM pool allocation
- No pre-allocation mechanism exists to reserve IP ranges in IPAM pools
- Explicit subnet IP ranges provide reliable and deterministic deployments

**Note:** Subnets created with explicit `address_prefixes` will show as "Unallocated" in Azure Virtual Network Manager IPAM. This is expected and means the subnet wasn't allocated through IPAM pools, but Azure will still prevent IP conflicts.

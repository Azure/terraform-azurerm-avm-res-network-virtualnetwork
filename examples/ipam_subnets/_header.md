# IPAM-Enabled Virtual Network with Time-Delayed Sequential Subnet Creation

This example demonstrates Azure IPAM (IP Address Management) integration with the AVM Virtual Network module, featuring **time-delayed sequential subnet creation** to prevent parallel allocation conflicts.

## 🎯 Problem Solved

When multiple subnets request address space from the same IPAM pool simultaneously, Azure IPAM may allocate overlapping IP ranges, causing deployment failures:

```
NetcfgSubnetRangesOverlap - Subnet subnet2-ipam with address range 10.0.0.0/26 overlaps with subnet subnet1-ipam with address range 10.0.0.0/26
```

This example provides a **production-ready solution** that eliminates these conflicts while maintaining simplicity.

## 🏗️ Architecture

### IPAM Components
- **Network Manager**: Manages IPAM pools and policies
- **IPAM Pool**: Contains available IP address space (`10.0.0.0/16`)
- **VNet with IPAM**: Virtual network gets address space from IPAM pool
- **Sequential Subnets**: Subnets allocated sequentially to prevent conflicts

### Time-Delayed Sequential Creation
1. **t=0s**: VNet + first IPAM subnet created immediately
2. **t=45s**: Second IPAM subnet starts creation
3. **t=90s**: Third IPAM subnet starts creation
4. **Non-IPAM subnets**: Created immediately in parallel

## 📝 Configuration Examples

### Basic IPAM VNet with Sequential Subnets

```hcl
module "vnet_ipam" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  location            = "East US 2"
  resource_group_name = "rg-ipam-example"
  name                = "vnet-ipam-example"

  # VNet gets /24 address space from IPAM pool
  ipam_pools = [{
    id            = azapi_resource.ipam_pool.id
    prefix_length = 24
  }]

  # Configure delay between IPAM subnet creations (prevents conflicts)
  ipam_subnet_allocation_delay = 45  # 45 seconds between each

  subnets = {
    # IPAM subnets (created sequentially)
    web_subnet = {
      name = "subnet-web"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26  # /26 = 64 addresses
      }]
    }

    app_subnet = {
      name = "subnet-app"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26  # /26 = 64 addresses
      }]
      # Will be created 45 seconds after web_subnet
    }

    data_subnet = {
      name = "subnet-data"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 27  # /27 = 32 addresses
      }]
      # Will be created 90 seconds after web_subnet
    }
  }
}
```

### Mixed IPAM and Traditional Subnets

```hcl
subnets = {
  # IPAM-allocated subnet
  dynamic_subnet = {
    name = "subnet-dynamic"
    ipam_pools = [{
      pool_id       = azapi_resource.ipam_pool.id
      prefix_length = 26
    }]
  }

  # Traditional static subnet
  management_subnet = {
    name             = "subnet-management"
    address_prefixes = ["10.0.0.192/26"]
  }

  # Calculated subnet from VNet address space
  services_subnet = {
    name                = "subnet-services"
    calculate_from_vnet = true
    prefix_length       = 27
  }
}
```

## 🔧 Configuration Options

### IPAM Pool Configuration
```hcl
# At VNet level - for VNet address space
ipam_pools = [{
  id            = "/subscriptions/.../ipamPools/my-pool"
  prefix_length = 24  # VNet gets /24 from pool
}]

# At Subnet level - for subnet address allocation
subnets = {
  my_subnet = {
    ipam_pools = [{
      pool_id         = "/subscriptions/.../ipamPools/my-pool"
      prefix_length   = 26  # Subnet gets /26 from VNet's /24
      allocation_type = "Static"  # or "Dynamic"
    }]
  }
}
```

### Timing Configuration
```hcl
# Adjust delay based on your environment
ipam_subnet_allocation_delay = 30   # Fast regions
ipam_subnet_allocation_delay = 45   # Default (recommended)
ipam_subnet_allocation_delay = 60   # Slow regions or many subnets
ipam_subnet_allocation_delay = 0    # Disable delays (not recommended)
```

## 🚀 Usage Patterns

### New IPAM-Managed Infrastructure
```hcl
# 1. Create Network Manager + IPAM Pool
resource "azapi_resource" "network_manager" { /* ... */ }
resource "azapi_resource" "ipam_pool" { /* ... */ }

# 2. Create IPAM-enabled VNet with sequential subnets
module "vnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  ipam_pools = [{ id = azapi_resource.ipam_pool.id, prefix_length = 24 }]
  ipam_subnet_allocation_delay = 45

  subnets = { /* IPAM subnets */ }
}
```

### Adding Subnets to Existing IPAM VNet
```hcl
# Use the subnet submodule independently
module "additional_subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  name            = "subnet-additional"
  virtual_network = { resource_id = "/subscriptions/.../virtualNetworks/existing-vnet" }

  # No IPAM - uses traditional addressing
  address_prefix = "10.0.1.0/24"
}
```

## 📊 Real-World Results

After successful deployment, you'll see non-overlapping IPAM allocations:

```bash
terraform show
# VNet: 10.0.0.0/24      (from IPAM pool)
# ├── web_subnet:  10.0.0.0/26    (64 addresses)
# ├── app_subnet:  10.0.0.64/26   (64 addresses)
# ├── data_subnet: 10.0.0.128/27  (32 addresses)
# └── mgmt_subnet: 10.0.0.192/26  (static)
```

## ⚡ Performance & Timing

| Subnets | Delay (45s) | Total Time | Parallel Time |
|---------|-------------|------------|---------------|
| 3 IPAM  | 90s        | ~2min      | ~30s (conflicts) |
| 5 IPAM  | 180s       | ~3min      | ~30s (conflicts) |
| 10 IPAM | 405s       | ~7min      | ~30s (conflicts) |

**Trade-off**: Slightly longer deployment time for guaranteed conflict-free allocation.

## 🔍 Troubleshooting

### Common Issues

1. **VNet Address Space Mismatch**
   ```
   Error: VNet prefixes are not in scope of pool
   ```
   **Solution**: Ensure IPAM pool contains the address range needed

2. **Subnet Outside VNet Range**
   ```
   Error: Subnet IP address range is outside the VNet range
   ```
   **Solution**: Use IPAM for VNet address space or ensure static subnets fit

3. **Pool Allocation Conflicts**
   ```
   Error: NetcfgSubnetRangesOverlap
   ```
   **Solution**: Increase `ipam_subnet_allocation_delay` or ensure sequential creation

## 📚 Additional Resources

- [Azure IPAM Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/ip-address-management)
- [Network Manager Documentation](https://docs.microsoft.com/en-us/azure/virtual-network-manager/)
- [AVM Virtual Network Module](../../README.md)

---

This example provides a **production-ready solution** for IPAM subnet allocation conflicts while maintaining the simplicity customers expect from AVM modules.

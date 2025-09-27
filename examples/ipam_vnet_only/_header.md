# IPAM VNet Only Example

This example demonstrates using IPAM for virtual network address space allocation while using traditional addressing methods for subnets.

## Use Case

This pattern is ideal when you want:
- **Centralized VNet address management** through IPAM pools
- **Predictable subnet addressing** using traditional methods
- **Integration with existing subnet management practices**
- **Avoiding IPAM subnet allocation timing complexities**

## Features Demonstrated

### VNet IPAM
- ✅ **VNet address space from IPAM pool** - Dynamic allocation from centralized pool
- ✅ **Flexible pool sizing** - /16 VNet allocated from /12 pool
- ✅ **Integration with existing workflows** - Standard subnet creation patterns

### Traditional Subnet Management
- ✅ **Calculated addressing** - Subnets calculated from IPAM-allocated VNet space
- ✅ **Static addressing** - Manual subnet definition within VNet range
- ✅ **Subnet module integration** - Adding subnets using standalone subnet module
- ✅ **Standard network features** - NSGs, service endpoints, delegations work normally

### Mixed Deployment Patterns
- ✅ **Main module subnets** - Subnets created with VNet
- ✅ **Subnet module extension** - Additional subnets added independently
- ✅ **No timing constraints** - All subnets created in parallel (no delays needed)

## Architecture

```
IPAM Pool (172.16.0.0/12)
│
└── VNet (/16 dynamically allocated, e.g., 172.16.0.0/16)
    ├── subnet-web (172.16.0.0/24) - calculated from VNet
    ├── subnet-app (172.16.1.0/24) - calculated from VNet
    ├── subnet-data (172.16.2.0/25) - calculated from VNet
    ├── subnet-management (172.16.255.240/28) - static addressing
    └── subnet-additional (172.16.2.128/27) - added via subnet module
```

## Deployment Benefits

### Simplified Management
- **No time delays** required between subnet creations
- **Parallel deployment** of all subnets for faster provisioning
- **Predictable addressing** with calculated or static methods

### Enterprise Integration
- **Centralized IP governance** through IPAM pools for VNet allocation
- **Familiar subnet patterns** for operations teams
- **Easy expansion** using subnet module for additional subnets

### Operational Advantages
- **Faster deployments** without sequential subnet creation delays
- **Standard troubleshooting** using traditional networking tools
- **Flexible subnet sizing** without IPAM pool constraints

## Resource Creation Timeline

```
t=0s: All resources created in parallel
├── VNet with IPAM pool allocation
├── subnet-web (calculated)
├── subnet-app (calculated)
├── subnet-data (calculated)
├── subnet-management (static)
└── subnet-additional (via subnet module)
```

## Usage Patterns

### 1. Calculated Subnets (Recommended)
```hcl
subnets = {
  web = {
    name                = "subnet-web"
    calculate_from_vnet = true
    prefix_length       = 24
    subnet_index        = 0
  }
}
```

### 2. Static Subnets (When Address is Known)
```hcl
subnets = {
  management = {
    name             = "subnet-management"
    address_prefixes = ["172.16.255.240/28"]
  }
}
```

### 3. Subnet Module Extension
```hcl
module "additional_subnet" {
  source = "../../modules/subnet"

  virtual_network = {
    resource_id = module.vnet.resource_id
  }
  calculate_from_vnet = true
  prefix_length       = 27
  subnet_index        = 2
}
```

## When to Use This Pattern

### ✅ Ideal For:
- **Hybrid IPAM adoption** - Gradual migration to IPAM
- **Existing subnet management** - Teams comfortable with traditional addressing
- **Performance-critical deployments** - No delays needed for subnet creation
- **Complex subnet requirements** - Custom addressing schemes within IPAM VNets

### ⚠️ Consider Alternatives When:
- **Full IPAM governance** required for subnets
- **Large-scale automated subnet provisioning** needed
- **Complete IP address lifecycle management** is priority

## Expected Outputs

- **VNet with IPAM-allocated address space** (e.g., 172.16.0.0/16)
- **5 subnets total** using different addressing methods:
  - 3 calculated subnets from VNet space
  - 1 static subnet with manual addressing
  - 1 additional subnet via subnet module
- **Fast parallel deployment** of all subnet resources
- **Standard network associations** (NSGs, service endpoints)

## Troubleshooting

### Common Issues
1. **Static Subnet Outside VNet Range**: Ensure static addresses fit within IPAM-allocated VNet space
2. **Calculated Subnet Conflicts**: Check subnet_index values for overlaps
3. **VNet Address Unknown**: Use data sources or outputs to reference IPAM-allocated ranges

### Best Practices
- Use calculated addressing when possible for automatic conflict avoidance
- Reserve high address ranges (e.g., .240/28) for static management subnets
- Monitor IPAM pool utilization to ensure sufficient space for VNet allocations

This pattern provides the best of both worlds: centralized VNet governance through IPAM with flexible, familiar subnet management practices.

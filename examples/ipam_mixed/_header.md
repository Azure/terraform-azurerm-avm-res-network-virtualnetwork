# IPAM Mixed Example

This example demonstrates real-world mixed addressing scenarios, combining traditional VNet management with IPAM for specific use cases.

## Use Case

This pattern addresses common enterprise scenarios where:
- **Infrastructure subnets** need predictable, static addressing (management, bastion, gateway)
- **Workload subnets** benefit from dynamic IPAM allocation for scalability
- **Hybrid environments** require both addressing methods within the same deployment
- **Migration scenarios** gradually adopt IPAM without disrupting existing networks

## Features Demonstrated

### Traditional VNet with Mixed Subnets
- ✅ **Static infrastructure subnets** - Management, Bastion, Gateway subnets with predictable addresses
- ✅ **IPAM workload subnets** - Dynamic allocation for application tiers
- ✅ **Calculated subnets** - Efficient use of remaining VNet address space
- ✅ **Special Azure subnets** - Proper handling of AzureBastionSubnet and GatewaySubnet

### Pure IPAM VNet for Scalability
- ✅ **Microservices deployment** - Multiple small IPAM subnets for containerized workloads
- ✅ **Dynamic scaling** - Easy addition of new microservice subnets
- ✅ **Consistent sizing** - IPAM ensures appropriate subnet sizes

### Cross-VNet Integration
- ✅ **VNet peering** between traditional and IPAM VNets
- ✅ **Hybrid connectivity** - Traditional and IPAM networks working together
- ✅ **Centralized management** - Single IPAM pool serving multiple deployment patterns

## Architecture

```
Traditional VNet (10.0.0.0/16)
├── Static Infrastructure Subnets (immediate creation)
│   ├── subnet-management (10.0.0.0/24) - Static
│   ├── AzureBastionSubnet (10.0.1.0/26) - Static
│   └── GatewaySubnet (10.0.2.0/27) - Static
├── IPAM Workload Subnets (sequential creation)
│   ├── subnet-web-workload (from IPAM pool)
│   ├── subnet-app-workload (from IPAM pool)
│   └── subnet-data-workload (from IPAM pool)
└── Calculated Subnet
    └── subnet-shared-services (10.0.3.0/27) - Calculated

IPAM VNet (from 10.100.0.0/16 pool)
├── Pure IPAM Allocation (/20 from pool)
└── Microservice Subnets (all from IPAM pool)
    ├── subnet-microservice-1 (/26)
    ├── subnet-microservice-2 (/26)
    └── subnet-microservice-3 (/27)

VNet Peering: Traditional ↔ IPAM
```

## Deployment Timeline

### Traditional VNet with Mixed Subnets
```
t=0s:    VNet created with static address space
t=0s:    Static subnets created in parallel:
         ├── management (10.0.0.0/24)
         ├── AzureBastionSubnet (10.0.1.0/26)
         ├── GatewaySubnet (10.0.2.0/27)
         └── shared-services (calculated)
t=0s:    web-workload IPAM subnet starts
t=30s:   app-workload IPAM subnet starts
t=60s:   data-workload IPAM subnet starts
```

### IPAM VNet for Microservices
```
t=0s:    VNet created with IPAM allocation
t=0s:    microservice-1 IPAM subnet starts
t=30s:   microservice-2 IPAM subnet starts
t=60s:   microservice-3 IPAM subnet starts
```

## Key Patterns

### 1. Infrastructure vs Workload Segregation
```hcl
# Infrastructure - Static addressing for predictable management
management = {
  name             = "subnet-management"
  address_prefixes = ["10.0.0.0/24"]
}

# Workloads - IPAM for dynamic scaling
web_workload = {
  name = "subnet-web-workload"
  ipam_pools = [{
    pool_id       = azapi_resource.ipam_pool_workloads.id
    prefix_length = 24
  }]
}
```

### 2. Azure Special Subnets
```hcl
# Azure requires specific subnet names for certain services
bastion = {
  name             = "AzureBastionSubnet"  # Must be exact name
  address_prefixes = ["10.0.1.0/26"]     # Minimum /26 required
}

gateway = {
  name             = "GatewaySubnet"      # Must be exact name
  address_prefixes = ["10.0.2.0/27"]     # Minimum /27 required
}
```

### 3. Efficient Space Utilization
```hcl
# Use remaining VNet space efficiently
shared_services = {
  name                = "subnet-shared-services"
  calculate_from_vnet = true
  prefix_length       = 27
  subnet_index        = 0  # First available /27
}
```

## Benefits of This Approach

### Operational Benefits
- **Predictable Infrastructure**: Management, bastion, and gateway subnets have known addresses
- **Scalable Workloads**: Application subnets can be dynamically provisioned
- **Gradual IPAM Adoption**: Mix traditional and IPAM methods during migration
- **Standard Azure Services**: Special subnets work with established patterns

### Technical Benefits
- **Parallel Infrastructure Deployment**: Static subnets deploy immediately
- **Controlled Workload Scaling**: IPAM prevents workload subnet conflicts
- **Cross-VNet Connectivity**: Traditional and IPAM VNets can peer seamlessly
- **Flexible Governance**: Different policies for infrastructure vs workload subnets

### Enterprise Benefits
- **Risk Mitigation**: Critical infrastructure uses proven static addressing
- **Innovation Enablement**: Workloads leverage modern IPAM capabilities
- **Compliance**: Infrastructure subnets meet audit and documentation requirements
- **Future-Proofing**: Easy migration path to full IPAM adoption

## Expected Outputs

### Traditional VNet with Mixed Addressing
- **Static infrastructure subnets** (management, bastion, gateway, shared-services)
- **IPAM workload subnets** dynamically allocated from pool
- **No addressing conflicts** between static and IPAM subnets

### Pure IPAM VNet
- **All subnets from IPAM pool** for consistent governance
- **Microservice-sized subnets** (/26, /27) for containerized workloads
- **Easy horizontal scaling** for additional microservices

### Cross-VNet Connectivity
- **VNet peering** enabling communication between deployment patterns
- **Hybrid network topology** supporting diverse application requirements

## When to Use This Pattern

### ✅ Ideal For:
- **Enterprise migrations** from traditional to IPAM networking
- **Hybrid application portfolios** with different addressing needs
- **Regulated environments** requiring predictable infrastructure addresses
- **DevOps workflows** balancing control and automation

### ✅ Specific Scenarios:
- Hub-and-spoke architectures with mixed addressing needs
- Microservices platforms requiring many small, dynamic subnets
- Integration of legacy applications with cloud-native workloads
- Multi-team environments with different networking preferences

## Best Practices

1. **Reserve static ranges** for infrastructure at known addresses (e.g., 10.0.0.0/24)
2. **Use IPAM for workloads** that frequently scale up/down
3. **Plan address space carefully** to avoid conflicts between static and IPAM ranges
4. **Implement consistent tagging** to distinguish static vs IPAM resources
5. **Monitor pool utilization** to ensure sufficient space for IPAM growth

This pattern provides maximum flexibility while maintaining operational simplicity for mixed enterprise networking requirements.

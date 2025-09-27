# Azure Virtual Network Module - Documentation Index

Welcome to the Azure Virtual Network (AVM) module documentation. This module provides comprehensive support for Azure Virtual Networks including advanced IPAM (IP Address Management) capabilities.

## 📚 Documentation Structure

### Core Documentation
- **[README.md](README.md)** - Main module documentation with basic usage, variables, and outputs
- **[IPAM_GUIDE.md](IPAM_GUIDE.md)** - Comprehensive guide for Azure IPAM integration and usage patterns

### Module Documentation
- **[Subnet Module README](modules/subnet/README.md)** - Standalone subnet module with IPAM considerations

### Examples
- **[Basic VNet Examples](examples/)** - Standard virtual network configurations
- **[IPAM Examples](examples/ipam_timed_subnets/)** - Complete IPAM implementation with time-delayed subnet creation

## 🚀 Quick Start

### Standard Virtual Network
```hcl
module "vnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  location            = "East US 2"
  resource_group_name = "rg-networking"
  name                = "vnet-standard"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    web = {
      name             = "subnet-web"
      address_prefixes = ["10.0.1.0/24"]
    }
  }
}
```

### IPAM-Managed Virtual Network
```hcl
module "vnet_ipam" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  location            = "East US 2"
  resource_group_name = "rg-networking"
  name                = "vnet-ipam"

  # VNet gets address space from IPAM pool
  ipam_pools = [{
    id            = azapi_resource.ipam_pool.id
    prefix_length = 24
  }]

  # Subnets allocated from same pool with time delays
  ipam_subnet_allocation_delay = 45
  subnets = {
    web = {
      name = "subnet-web"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26
      }]
    }
  }
}
```

## 🏗️ Architecture Patterns

### Pattern 1: Traditional Static Addressing
- **Use Case**: Predictable, well-planned network architectures
- **Benefits**: Full control, no dependencies on IPAM infrastructure
- **Documentation**: [Standard Examples](examples/)

### Pattern 2: IPAM-Managed Networks
- **Use Case**: Large-scale, centrally managed network deployments
- **Benefits**: Automated address allocation, conflict prevention, centralized governance
- **Documentation**: [IPAM Guide](IPAM_GUIDE.md)

### Pattern 3: Hybrid Approach
- **Use Case**: Migration scenarios or mixed requirements
- **Benefits**: IPAM for workloads, static for management/reserved ranges
- **Documentation**: [Mixed Scenarios](IPAM_GUIDE.md#mixed-scenarios)

### Pattern 4: Subnet-Only Deployments
- **Use Case**: Adding subnets to existing VNets
- **Benefits**: Modular deployment, reusable subnet configurations
- **Documentation**: [Subnet Module](modules/subnet/README.md)

## 🔧 Feature Matrix

| Feature | Main Module | Subnet Module |
|---------|-------------|---------------|
| **Basic Subnet Creation** | ✅ | ✅ |
| **Static Address Assignment** | ✅ | ✅ |
| **VNet IPAM Pools** | ✅ | ❌ |
| **Subnet IPAM Pools** | ✅ | ❌ |
| **Time-Delayed Creation** | ✅ | ❌ |
| **NSG Association** | ✅ | ✅ |
| **Route Table Association** | ✅ | ✅ |
| **Service Endpoints** | ✅ | ✅ |
| **Subnet Delegation** | ✅ | ✅ |
| **Calculated Addressing** | ✅ | ✅ |

## 📖 Learning Path

### Beginner
1. Start with [README.md](README.md) for basic concepts
2. Try [basic examples](examples/) for standard scenarios
3. Understand subnet creation with [subnet module](modules/subnet/README.md)

### Intermediate
1. Learn IPAM fundamentals in [IPAM Guide](IPAM_GUIDE.md#overview)
2. Implement basic IPAM with [VNet IPAM configuration](IPAM_GUIDE.md#vnet-ipam-configuration)
3. Explore [mixed scenarios](IPAM_GUIDE.md#mixed-scenarios) for hybrid approaches

### Advanced
1. Master [subnet IPAM configuration](IPAM_GUIDE.md#subnet-ipam-configuration) with time delays
2. Implement [complex IPAM scenarios](examples/ipam_timed_subnets/)
3. Use [troubleshooting guide](IPAM_GUIDE.md#troubleshooting) for production issues

## 🛠️ Common Use Cases

### Enterprise Hub-and-Spoke
- **Challenge**: Consistent addressing across multiple environments
- **Solution**: IPAM pools with hierarchical allocation
- **Reference**: [IPAM Guide - VNet Configuration](IPAM_GUIDE.md#vnet-ipam-configuration)

### Multi-Region Deployments
- **Challenge**: Avoiding address conflicts across regions
- **Solution**: Region-specific IPAM pools
- **Reference**: [IPAM Guide - Multiple Pools](IPAM_GUIDE.md#multiple-ipam-pools-ipv4--ipv6)

### Brownfield Network Integration
- **Challenge**: Adding IPAM to existing static networks
- **Solution**: Hybrid addressing with careful conflict avoidance
- **Reference**: [Mixed Scenarios](IPAM_GUIDE.md#mixed-scenarios)

### Microservices Architecture
- **Challenge**: Many small subnets with automated allocation
- **Solution**: Time-delayed IPAM subnet creation
- **Reference**: [Sequential Creation](IPAM_GUIDE.md#time-delayed-sequential-ipam-subnets)

## 🔍 Troubleshooting Quick Reference

| Issue | Documentation |
|-------|---------------|
| **NetcfgSubnetRangesOverlap** | [IPAM Guide - Common Issues](IPAM_GUIDE.md#1-netcfgsubnetrangesoverlap-error) |
| **VNet Address Space Mismatch** | [IPAM Guide - Troubleshooting](IPAM_GUIDE.md#2-vnet-address-space-mismatch) |
| **IPAM Pool Exhaustion** | [IPAM Guide - Pool Failures](IPAM_GUIDE.md#4-pool-allocation-failures) |
| **Subnet Module IPAM** | [Subnet Module - IPAM Considerations](modules/subnet/README.md#ipam-considerations) |

## 🎯 Decision Matrix

### When to Use Main Module
- ✅ Creating new VNets with or without IPAM
- ✅ Need multiple subnets with coordinated creation
- ✅ IPAM pool allocation required
- ✅ Complex networking with multiple associations

### When to Use Subnet Module
- ✅ Adding subnets to existing VNets
- ✅ Modular subnet deployment patterns
- ✅ Simple subnet creation without IPAM pools
- ✅ Independent subnet lifecycle management

### IPAM vs Static Addressing
| Scenario | IPAM | Static | Hybrid |
|----------|------|---------|--------|
| **Large Scale (100+ subnets)** | ✅ | ❌ | ✅ |
| **Multi-Environment** | ✅ | ⚠️ | ✅ |
| **Regulatory/Compliance** | ⚠️ | ✅ | ✅ |
| **Rapid Deployment** | ✅ | ❌ | ⚠️ |
| **Existing Networks** | ❌ | ✅ | ✅ |

## 🔗 External References

- **[Azure Virtual Network Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/)**
- **[Azure IPAM Documentation](https://docs.microsoft.com/en-us/azure/virtual-network-manager/concept-ip-address-management)**
- **[Terraform AzAPI Provider](https://registry.terraform.io/providers/Azure/azapi/latest/docs)**
- **[Azure Resource Manager Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/)**

## 📞 Support and Contribution

- **Issues**: Report issues on [GitHub Issues](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/issues)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines
- **Community**: Join discussions in [Azure Terraform Community](https://github.com/Azure/terraform-azurerm-avm)

---

*This documentation is maintained alongside the module and reflects the latest features and best practices for Azure Virtual Network deployment with Terraform.*

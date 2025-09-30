# IPAM Full Example

This example demonstrates comprehensive IPAM usage with the Azure Virtual Network module, showcasing all major IPAM capabilities in a single deployment.

## Features Demonstrated

### Virtual Network IPAM
- ✅ **Dual-stack allocation** - IPv4 and IPv6 address spaces from separate IPAM pools
- ✅ **Large address space** - /20 IPv4 pool providing ~4000 IP addresses
- ✅ **Automatic allocation** - VNet address space allocated dynamically from pools

### Subnet IPAM with Conflict Prevention
- ✅ **Time-delayed sequential creation** - Multiple IPAM subnets created with automatic delays
- ✅ **Mixed subnet types** - IPAM subnets alongside traditional static subnets
- ✅ **Variable subnet sizes** - /24, /25, /26, /27 allocations from the same pool
- ✅ **Dual-stack subnets** - IPv4 and IPv6 allocation for the same subnet
- ✅ **Subnet delegation** - IPAM subnet with container instance delegation

### Network Associations
- ✅ **Network Security Groups** - Different NSGs per tier (web, app, data)
- ✅ **Route Tables** - Custom routing for IPAM subnets
- ✅ **Service Endpoints** - Storage, SQL, KeyVault endpoints on IPAM subnets

## Deployment Timeline

The module automatically handles sequential IPAM subnet creation:

```
t=0s:    VNet created with IPAM pools
t=0s:    management subnet (static) created in parallel
t=0s:    web subnet (IPAM) starts
t=30s:   app subnet (IPAM) starts
t=60s:   data subnet (IPAM) starts
t=90s:   services subnet (dual-stack IPAM) starts
t=120s:  containerinstances subnet (IPAM with delegation) starts
```

## Architecture

```
IPAM Pool (10.0.0.0/14)
│
└── VNet (/20 allocated from pool)
    ├── subnet-web-ipam (/24 from pool) + NSG + Route Table
    ├── subnet-app-ipam (/24 from pool) + NSG + Route Table
    ├── subnet-data-ipam (/25 from pool) + NSG
    ├── subnet-management (static /28) + NSG
    ├── subnet-services-dual (/26 IPv4 + /64 IPv6) + Service Endpoints
    └── subnet-aci (/27 from pool) + Container Delegation

IPv6 Pool (fdea:5251:1c0a::/48)
│
└── VNet (/56 allocated from pool)
    └── subnet-services-dual (/64 from pool)
```

## Resource Creation Order

1. **Infrastructure Setup** (parallel)
   - Resource Group
   - Network Manager
   - IPAM Pools (IPv4 + IPv6)
   - Network Security Groups
   - Route Table

2. **VNet Creation**
   - VNet with IPAM pool allocation
   - DNS servers configuration

3. **Subnet Creation** (mixed parallel/sequential)
   - Static management subnet (immediate, parallel)
   - IPAM subnets (sequential with 30s delays)

## Usage

```hcl
# Prerequisites: Ensure IPAM is available in your target region
# Supported regions: East US 2, West US 2, West Europe (and others)

terraform init
terraform plan
terraform apply
```

## Expected Outputs

- **VNet with IPAM-allocated address space** (e.g., 10.0.64.0/20)
- **6 subnets total**:
  - 5 IPAM-allocated subnets of various sizes
  - 1 statically addressed management subnet
- **Proper network associations** (NSGs, route tables, service endpoints)
- **No IP address conflicts** due to automatic sequential creation

## Key Learning Points

1. **Default Timing**: The module uses a default 30-second delay between IPAM subnet allocations
2. **Mixed Addressing**: IPAM and static subnets work together seamlessly
3. **Dual-Stack Support**: Single subnet can have both IPv4 and IPv6 from different pools
4. **Conflict Prevention**: Time delays ensure reliable IPAM deployments at scale
5. **Production Ready**: All standard network features work with IPAM subnets

## Troubleshooting

If you encounter deployment issues:

1. **Check IPAM Region Support**: Ensure your region supports IPAM
2. **Verify Pool Capacity**: Ensure IPAM pool has sufficient address space
3. **Monitor Timing**: Watch for any time-delay related issues in logs
4. **Review Permissions**: Ensure proper Network Manager access

This example serves as the comprehensive test case for the module's IPAM capabilities and demonstrates production-ready patterns for large-scale deployments.

# Azure Virtual Network Module

This module is used to manage Azure Virtual Networks, Subnets and Peerings, with optional IPAM (IP Address Management) support.

This module is composite and includes sub modules that can be used independently for pre-existing virtual networks. These sub modules are:

- subnet - The subnet module is used to manage subnets within a virtual network.
- peering - The peering module is used to manage virtual network peerings.

## Features

This module supports managing virtual networks and their associated subnets and peerings together or independently.

The module supports:

- Creating a new virtual network
- Creating a new subnet
- Creating a new virtual network peering
- Associating DNS servers with a virtual network
- Associating a DDOS protection plan with a virtual network
- Associating a network security group with a subnet
- Associating a route table with a subnet
- Associating a service endpoint with a subnet
- Associating a virtual network gateway with a subnet
- Assigning delegations to subnets
- **IPAM pool allocation for virtual network address space**
- **IPAM pool allocation for individual subnets**
- **Choice of IPAM or traditional static addressing per virtual network**

## IPAM Support

This module provides comprehensive IPAM (IP Address Management) support through Azure Virtual Network Manager IPAM pools.

### What IPAM Provides
- **VNet address space allocation** from centralized IPAM pools
- **Subnet address allocation** from IPAM pools
- **Dual-stack support** - one IPv4 pool and one IPv6 pool per virtual network
- **All standard subnet features** work with IPAM subnets (NSGs, service endpoints, delegations, etc.)

### Benefits
- **Centralized IP governance** through Azure Network Manager
- **Automatic conflict prevention** during address allocation
- **Simplified address management** across multiple deployments

### IPAM Regional Support

**⚠️ IPAM NOT supported in these regions:**
`chilecentral`, `jioindiawest`, `malaysiawest`, `qatarcentral`, `southafricawest`, `westindia`, `westus3`

**Note:** IPAM is available in all other regions where Azure Virtual Network Manager is supported. For the most up-to-date regional availability, consult the [Azure products by region](https://azure.microsoft.com/explore/global-infrastructure/products-by-region/) page.

### IPAM Examples
- **[ipam_basic](examples/ipam_basic/)** - Complete IPAM usage with VNet and multiple subnets
- **[existing_vnet_ipam_subnets](examples/existing_vnet_ipam_subnets/)** - Adding IPAM subnets to existing VNet managed by IPAM
- **[ipam_vnet_only](examples/ipam_vnet_only/)** - IPAM VNet creation without subnets

### IPAM Allocation Rules and Sizing

Address space is requested from an IPAM pool as a **single allocation per pool**. The following are enforced by the Azure Resource Provider (they are platform rules, not module limitations):

| Rule | Detail |
|------|--------|
| One pool per IP type | At most one IPv4 pool and one IPv6 pool per virtual network. |
| No duplicate pools | The same pool cannot be referenced more than once on a VNet or subnet. |
| No IPAM + static mix | A virtual network uses either IPAM pools or a static `address_space`, not both. |
| Subnet pools are a subset | A subnet may only reference pools that its virtual network already uses. |

**Sizing:** set the size on the single pool entry using either `number_of_ip_addresses` (for example `"256"`) or `prefix_length` (for example `24`). To request more address space from a pool, increase that value - do **not** add a second entry for the same pool.

**Resolved prefixes (summarization vs. fragmentation):** Azure resolves one allocation into one or more CIDR blocks. Contiguous free space is summarized into a single larger prefix (for example two `/21` worth of space surface as one `/20`); fragmented free space is returned as multiple non-adjacent prefixes (for example a single allocation may surface as `/25` + `/28`). This is why one pool can show a varying number of address prefixes. The module exposes these resolved prefixes as a **read-only** output, so summarization or fragmentation does **not** cause Terraform drift.

## Ignoring out-of-band subnet changes (`ignore_body_changes`)

Some Azure controllers modify subnet properties **out-of-band** - outside Terraform - after the subnet is created. The most common case is **Azure Virtual Network Manager (AVNM)** routing configurations (or Azure Policy `DeployIfNotExists`) attaching a **managed route table** to a subnet. On the next `terraform plan` the module sees the externally-added `routeTable` and tries to revert it to the configured value (`null`), producing **perpetual drift** and fighting the external controller on every apply.

Each subnet accepts an optional `ignore_body_changes` list. It maps to the `azapi` provider's write-only [`ignore_body_changes`](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#ignore_body_changes) argument: the listed body paths are ignored after create, so the external controller can own them without drift.

```terraform
module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  # ... version, name, location, parent_id, address_space ...

  subnets = {
    workload = {
      name             = "snet-workload"
      address_prefixes = ["10.0.1.0/24"]

      # Let AVNM / Azure Policy own the route table association out-of-band.
      # Do NOT also set route_table on this subnet (see note below).
      ignore_body_changes = ["properties.routeTable"]
    }
  }
}
```

**Supported paths.** Any subnet body property expressed in dot notation and starting with `properties.`. The provider ignores whichever paths you list; it does not restrict them to a fixed set, so newer subnet properties work without a module change. Commonly used paths:

| Path | Property |
|------|----------|
| `properties.routeTable` | Route table association (AVNM routing / Policy DINE) - the canonical case |
| `properties.networkSecurityGroup` | Network security group association |
| `properties.serviceEndpoints` | Service endpoints |
| `properties.delegations` | Subnet delegations |

**Important - don't manage the same property twice.** Several of these properties are also settable through dedicated inputs (`route_table`, `network_security_group`, `service_endpoints`, `delegations`). When you ignore a path so an external controller can own it, leave the corresponding input **unset**. Setting the input *and* ignoring the path means the module renders a value the provider is told to ignore - confusing and self-defeating.

**Behaviour and requirements.**

- Entries must start with `properties.` and use dot notation. Individual list items cannot be targeted - ignore the whole list property. A bare name such as `"routeTable"` is silently ignored by the provider (it would not suppress drift), so the module rejects it with a validation error.
- `ignore_body_changes` is a **write-only** argument (stored in provider-private state), which requires **Terraform >= 1.11** and **AzAPI >= 2.12**. Changes to the list take effect only after an `apply`.
- While a path is ignored, configuration changes at that path are **not** sent to Azure until you remove the path from the list.
- Default is `[]` (nothing ignored) - existing configurations are unaffected.

## Prerequisites

### For IPAM Features
- **Azure Virtual Network Manager**: Required for all IPAM functionality
- **Supported Azure region**: IPAM must be available in your target region (see [Regional Support](#ipam-regional-support))
- **azapi provider**: Version ~> 2.12 required for IPAM resource management
- **Proper permissions**: Network Manager and IPAM pool management permissions

## Migrating from v0.1.x

Version 0.2.0 rewrote the module from `azurerm` resources to `azapi` resources and changed the state layout without shipping `moved` blocks. Current tooling can bridge the resource-type changes: [Terraform v1.8.0](https://github.com/hashicorp/terraform/releases/tag/v1.8.0) added provider-supported moves between resource types, and [AzAPI v2.1.0](https://github.com/Azure/terraform-provider-azapi/releases/tag/v2.1.0) added moves from `azurerm` resources to `azapi_resource`. This module requires Terraform `>= 1.11, < 2.0` and AzAPI `~> 2.12`.

The addresses below were verified against Terraform's move validation and AzAPI's cross-type state conversion using a synthetic v0.1.x state, but the migration has not been applied end to end against a real v0.1.3 deployment. Back up the state first, treat the addresses below as templates, and verify them against `terraform state list`.

### Move retained resources

Write the `moved` blocks in the root configuration that calls this module, not in the module source. Replace `module.vnet` with the actual module address and repeat the keyed blocks for every subnet and peering. The current configuration must use the existing Azure resource names: set each subnet `name` to its old map key and each peering `name` to the old generated value `peering-<key>`.

```terraform
moved {
  from = module.vnet.azurerm_virtual_network.vnet
  to   = module.vnet.azapi_resource.vnet
}

moved {
  from = module.vnet.azurerm_subnet.subnet["subnet_key"]
  to   = module.vnet.module.subnet["subnet_key"].azapi_resource.subnet
}

moved {
  from = module.vnet.azurerm_virtual_network_peering.vnet_peering["peering_key"]
  to   = module.vnet.module.peering["peering_key"].azapi_resource.this[0]
}
```

The static subnet destination is deliberately unindexed. The subnet submodule already declares `moved { from = azapi_resource.subnet, to = azapi_resource.subnet[0] }` for the v0.15.0 IPAM change, and Terraform rejects two statements that move into the same instance with an `Ambiguous move statements` error. Targeting the unindexed address lets Terraform chain the two moves. If the target subnet uses `ipam_pools`, target `module.vnet.module.subnet["subnet_key"].azapi_resource.subnet_ipam[0]` instead; that address is indexed because no such chained move exists for it. The peering destination is for the full-virtual-network peering used by v0.1.x and selected by the current default `peer_complete_vnets = true`.

### Remove resources folded into parent bodies

These v0.1.x resources have no destination address because v0.2.0 folded them into the virtual network or subnet body. Configure the equivalent current input first, then use `terraform state rm` for each address that exists:

| State address | Equivalent current configuration |
|---------------|----------------------------------|
| `module.vnet.azurerm_virtual_network_dns_servers.vnet_dns[0]` | `dns_servers` on the virtual network |
| `module.vnet.azurerm_subnet_network_security_group_association.vnet["subnet_key"]` | `subnets["subnet_key"].network_security_group` |
| `module.vnet.azurerm_subnet_route_table_association.vnet["subnet_key"]` | `subnets["subnet_key"].route_table` |
| `module.vnet.azurerm_subnet_nat_gateway_association.nat_gw["subnet_key"]` | `subnets["subnet_key"].nat_gateway` |

Do not remove an association from state until the current subnet configuration contains the same NSG, route table, or NAT gateway ID. Otherwise, a later subnet update can remove that association from Azure.

### Review the first plan

AzAPI's cross-type state conversion initializes `id`, `name`, `parent_id`, and `type`, but not `body`. The first plan after adding the moves therefore shows the configured body being reconciled; this is expected. Review and adjust the configuration until the plan contains only the expected state moves and in-place updates.

**Never apply a plan that replaces the virtual network, subnets, or peerings.** After applying the reviewed in-place migration, run `terraform plan` again and iterate until it reports no changes. If a non-replacing plan cannot be established, importing the existing resources into a fresh configuration and state remains the conservative alternative.

Later releases introduced these additional breaking changes:

| Version | Breaking change |
|---------|-----------------|
| [v0.11.0](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/releases/tag/v0.11.0) | Removed `resource_group_name` and `subscription_id`; supply the resource group resource ID with `parent_id`. |
| [v0.12.0](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/releases/tag/v0.12.0) | Removed the `retry` options `multiplier` and `randomization_factor`, including nested subnet and peering retry objects. |
| [v0.15.0](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/releases/tag/v0.15.0) | Removed `service_endpoints` in favor of `service_endpoints_with_location`, and required a `moved` block for existing IPAM subnets. Reversed in v0.20.0: `service_endpoints` is supported again with names only, while `service_endpoints_with_location` now raises a validation error. |
| [v0.19.0](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/releases/tag/v0.19.0) | Moved locks, role assignments, and diagnostic settings from `azurerm` to `azapi`. Locks and diagnostic settings migrate through `moved` blocks; role assignments are recreated once. |

Use [GitHub Releases](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/releases) as the authoritative changelog for all versions.

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Basic Virtual Network with Subnets

This example shows the most basic usage of the module. It creates a new virtual network with subnets using traditional static addressing.

```terraform
module "avm-res-network-virtualnetwork" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  address_space = ["10.0.0.0/16"]
  location      = "eastus2"
  name          = "vnet-demo-eastus2-001"
  parent_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo-eastus2-001"
  subnets = {
    "subnet1" = {
      name             = "subnet1"
      address_prefixes = ["10.0.0.0/24"]
    }
    "subnet2" = {
      name             = "subnet2"
      address_prefixes = ["10.0.1.0/24"]
    }
  }
}
```

### Example - IPAM Virtual Network with Multiple Subnets

This example demonstrates IPAM usage with both VNet and subnet address allocation from IPAM pools.

```terraform
module "avm-res-network-virtualnetwork" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  location  = "East US"
  name      = "myIPAMVNet"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup"

  # VNet address space from IPAM pool
  ipam_pools = [{
    id            = azapi_resource.ipam_pool.id
    prefix_length = 24
  }]

  # Multiple subnets allocated from IPAM pool
  subnets = {
    "web_subnet" = {
      name = "subnet-web"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26
      }]
    }
    "app_subnet" = {
      name = "subnet-app"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 26
      }]
    }
    "data_subnet" = {
      name = "subnet-data"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool.id
        prefix_length = 27
      }]
    }
  }
}
```

### Example - Create a subnet on a pre-existing Virtual Network

This example shows how to create a subnet for a pre-existing virtual network using the subnet module.

```terraform
module "avm-res-network-subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet"
  name             = "subnet1"
  address_prefixes = ["10.0.0.0/24"]
}
```

## Troubleshooting

### Common IPAM Issues

- **"IPAM subnet creation failed"**: Ensure parent VNet was created with IPAM pools for its address space
- **"Region not supported"**: Check the [IPAM Regional Support](#ipam-regional-support) section above
- **"Network Manager not found"**: Ensure Azure Virtual Network Manager exists before creating IPAM pools
- **"Subnet overlap errors"**: Module uses retry logic to handle allocation conflicts automatically
- **"Pool exhausted"**: Check that your IPAM pool has sufficient available address space for the requested subnets
- **`CannotHaveDuplicatePoolIds`**: The same pool is referenced more than once. Use a single `ipam_pools` entry and increase `number_of_ip_addresses` instead of adding duplicate entries.
- **`only one association of each IP type is allowed`**: Only one IPv4 pool and one IPv6 pool are permitted per virtual network. Remove the additional same-family pool.
- **`CannotMixAddressPrefixAndPoolInPayload`**: A virtual network cannot combine IPAM pools with a static `address_space`. Choose one addressing model.
- **`SubnetPoolsMustBeSubsetOfVnetPools`**: A subnet references a pool that its virtual network does not use. Reference the pool on the VNet first.
- **A single pool shows multiple or changing address prefixes**: Expected behavior. One allocation is resolved into one or more CIDRs (summarized when contiguous, split when fragmented). These resolved prefixes are read-only and do not cause Terraform drift.
```

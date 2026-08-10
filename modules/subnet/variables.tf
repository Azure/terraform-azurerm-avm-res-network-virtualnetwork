variable "name" {
  type        = string
  description = <<DESCRIPTION
(Optional) The name of the subnet to create.
DESCRIPTION
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = <<DESCRIPTION
(Required) The Virtual Network, into which the subnet will be created.
DESCRIPTION
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", var.parent_id))
    error_message = "The parent_id must be a valid Virtual Network resource ID"
  }
}

variable "address_prefix" {
  type        = string
  default     = null
  description = <<DESCRIPTION
(Optional) The address prefix for the subnet. One of `address_prefix`, `address_prefixes`, or `ipam_pools` must be supplied.
DESCRIPTION

  validation {
    condition     = var.address_prefix == null ? true : can(cidrhost(var.address_prefix, 0))
    error_message = "`address_prefix` must be a valid CIDR block, for example \"10.0.0.0/24\"."
  }
}

variable "address_prefixes" {
  type        = list(string)
  default     = null
  description = <<DESCRIPTION
(Optional) The address prefixes for the subnet. You can supply more than one address prefix. One of `address_prefix`, `address_prefixes`, or `ipam_pools` must be supplied.
DESCRIPTION

  validation {
    condition     = var.address_prefixes == null ? true : alltrue([for cidr in var.address_prefixes : can(cidrhost(cidr, 0))])
    error_message = "Each entry in `address_prefixes` must be a valid CIDR block, for example \"10.0.0.0/24\"."
  }
}

variable "default_outbound_access_enabled" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
(Optional) Determines whether default outbound internet access is enabled for this subnet. This can only be set at create time.

More details here: https://learn.microsoft.com/en-gb/azure/virtual-network/ip-services/default-outbound-access
DESCRIPTION
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    virtual_networks_subnets = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
(Optional) Subnet body property paths (dot notation, relative to the request body) whose changes the `azapi` provider should ignore after creation. Use this to let out-of-band controllers own specific subnet properties without producing perpetual `terraform plan` drift.

- `virtual_networks_subnets` - The list of ignored body paths for the subnet managed by this module.

The canonical use case is Azure Virtual Network Manager (AVNM) `ManagedOnly` routing configurations or Azure Policy `DeployIfNotExists` policies that attach a route table to the subnet out-of-band. Set `virtual_networks_subnets = ["properties.routeTable"]` so Terraform stops re-asserting `routeTable` and the external association survives subsequent plans.

Common paths:
- `properties.routeTable` - route table association (AVNM / Policy DINE)
- `properties.networkSecurityGroup` - network security group association
- `properties.serviceEndpoints` - service endpoints
- `properties.delegations` - subnet delegations
- `tags` - top-level tags applied out-of-band

Notes:
- Paths use dot notation and are relative to the subnet request body. Individual list items cannot be targeted; ignore the whole list property instead.
- **Important:** several of these properties are also settable through dedicated module inputs (for example `route_table`, `network_security_group`, `service_endpoints`, `delegations`). When you ignore a path so an out-of-band controller can own it, leave the corresponding input unset - do not manage the same property from both places, or the module and the external controller will fight over it.
- This is a write-only argument stored in provider-private state, so changes to it take effect only after an `apply` (a non-empty value requires Terraform >= 1.11).
- While a path is ignored, configuration changes at that path are not sent to Azure until the path is removed from this list.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for path in var.ignore_body_changes.virtual_networks_subnets : length(trimspace(path)) > 0])
    error_message = "Every ignore_body_changes.virtual_networks_subnets entry must be a non-empty body path (for example \"properties.routeTable\" or \"tags\"). Paths are relative to the subnet request body and use dot notation."
  }
}

variable "delegation" {
  type = list(object({
    name = string
    service_delegation = object({
      name = string
    })
  }))
  default     = null
  description = <<DESCRIPTION
(Optional) (This variable is deprecated, use `delegations` instead). A list of delegations to apply to the subnet. Each delegation supports the following:

- `name` - (Required) A name for this delegation.
- `service_delegation` - (Required) A block defining the service to delegate to. It supports the
  - `name` - (Required) The name of the service to delegate to.
DESCRIPTION
}

variable "delegations" {
  type = list(object({
    name = string
    service_delegation = object({
      name = string
    })
  }))
  default     = null
  description = <<DESCRIPTION
(Optional) A list of delegations to apply to the subnet. Each delegation supports the following:

- `name` - (Required) A name for this delegation.
- `service_delegation` - (Required) A block defining the service to delegate to. It supports the
  - `name` - (Required) The name of the service to delegate to.
DESCRIPTION
}

variable "ipam_pools" {
  type = list(object({
    pool_id                = string
    number_of_ip_addresses = optional(string)
    prefix_length          = optional(number)
  }))
  default     = null
  description = <<DESCRIPTION
(Optional) A list of IPAM pools to allocate subnet address space from. Each pool supports the following:

- `pool_id` - (Required) The ID of the IPAM pool to allocate from.
- `number_of_ip_addresses` - (Optional) The number of IP addresses to request from the IPAM pool. If not specified, it will be calculated based on the `prefix_length`.
- `prefix_length` - (Optional) The prefix length for the subnet allocation (e.g., 24 for a /24 subnet). Required if `number_of_ip_addresses` is not specified.

Note: Only one IPAM pool allocation per subnet is currently supported. When using IPAM pools, do not specify `address_prefix` or `address_prefixes`.
DESCRIPTION

  validation {
    condition     = var.ipam_pools == null ? true : length(var.ipam_pools) == 1
    error_message = "Only one IPAM pool allocation per subnet is supported."
  }
  validation {
    condition     = var.ipam_pools == null ? true : alltrue([for pool in var.ipam_pools : pool.number_of_ip_addresses != null || (pool.prefix_length != null && pool.prefix_length >= 16 && pool.prefix_length <= 30)])
    error_message = "Either number_of_ip_addresses or a prefix_length between 16 and 30 must be specified for each IPAM pool."
  }
}

variable "nat_gateway" {
  type = object({
    id = string
  })
  default     = null
  description = <<DESCRIPTION
(Optional) The ID of the NAT Gateway to associate with the subnet. Changing this forces a new resource to be created.
DESCRIPTION
}

variable "network_security_group" {
  type = object({
    id = string
  })
  default     = null
  description = <<DESCRIPTION
(Optional) The ID of the Network Security Group to associate with the subnet. Changing this forces a new resource to be created.
DESCRIPTION
}

variable "private_endpoint_network_policies" {
  type        = string
  default     = "Enabled"
  description = <<DESCRIPTION
(Optional) Enable or Disable network policies for the private endpoint on the subnet. Possible values are `Disabled`, `Enabled`, `NetworkSecurityGroupEnabled` and `RouteTableEnabled`. Defaults to `Enabled`.

This value is only applied when `private_endpoint_network_policies_enabled` is `true`. Set `private_endpoint_network_policies_enabled` to `false` to omit the `privateEndpointNetworkPolicies` property from the request entirely (required in regions that do not support it, e.g. South Africa West).
DESCRIPTION
  nullable    = false

  validation {
    condition     = can(regex("^(Disabled|Enabled|NetworkSecurityGroupEnabled|RouteTableEnabled)$", var.private_endpoint_network_policies))
    error_message = "private_endpoint_network_policies must be one of Disabled, Enabled, NetworkSecurityGroupEnabled, or RouteTableEnabled."
  }
}

variable "private_endpoint_network_policies_enabled" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
(Optional) Controls whether the `privateEndpointNetworkPolicies` property is sent to Azure for the subnet. Defaults to `true`.

When `true`, the value of `private_endpoint_network_policies` is applied. When `false`, the property is omitted from the request entirely, which is required in regions that do not support it (e.g. South Africa West) because they reject the property outright.

Note: unlike `private_link_service_network_policies_enabled` (where `false` sends `"Disabled"`), setting this to `false` removes the property from the request rather than sending a value. To send `"Disabled"`, leave this `true` and set `private_endpoint_network_policies = "Disabled"`.
DESCRIPTION
  nullable    = false
}

variable "private_link_service_network_policies_enabled" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
(Optional) Enable or Disable network policies for the private link service on the subnet. Setting this to `true` will **Enable** the policy and setting this to `false` will **Disable** the policy. Defaults to `true`.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex = optional(list(string), [
      "AnotherOperationInProgress",
      "ReferencedResourceNotProvisioned",
      "OperationNotAllowed",
      "NetcfgSubnetRangesOverlap",
      "BadRequest.*overlap",
      "Conflict.*subnet.*range",
      "subnet.*address.*conflict"
    ])
    interval_seconds     = optional(number, 15)
    max_interval_seconds = optional(number, 300)
  })
  default     = {}
  description = "Retry configuration for the resource operations, includes IPAM-specific error patterns"
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
(Optional) A map of role assignments to create on the subnet. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "route_table" {
  type = object({
    id = string
  })
  default     = null
  description = <<DESCRIPTION
(Optional) The ID of the route table to associate with the subnet.
DESCRIPTION
}

variable "service_endpoint_policies" {
  type = map(object({
    id = string
  }))
  default     = null
  description = <<DESCRIPTION
(Optional) A set of service endpoint policy IDs to associate with the subnet.
DESCRIPTION
}

variable "service_endpoints" {
  type        = set(string)
  default     = null
  description = <<DESCRIPTION
(Optional) A set of service endpoints to associate with the subnet, specified as a set of service names (e.g. `["Microsoft.Storage", "Microsoft.Sql"]`).

Locations are intentionally not configurable: Azure implicitly expands service-endpoint locations (for example, `Microsoft.Storage` in a region adds its paired region), which caused perpetual drift when locations were sent explicitly. See issues #22 and #39.
DESCRIPTION
}

# The variable is intentionally unused beyond its own validation: it exists
# solely so that setting the removed argument fails with a message naming the
# replacement, instead of Terraform's generic "unexpected argument" error.
# tflint-ignore: terraform_unused_declarations
variable "service_endpoints_with_location" {
  type = list(object({
    service   = string
    locations = optional(list(string), ["*"])
  }))
  default     = null
  description = <<DESCRIPTION
**Removed.** Use `service_endpoints` instead, which takes a set of service names.

This variable is still declared so that configurations which set it fail with an explanatory error naming the replacement, rather than the generic "unexpected argument" error. Setting it is always an error. It will be removed entirely in a future release.
DESCRIPTION

  validation {
    condition     = var.service_endpoints_with_location == null
    error_message = "`service_endpoints_with_location` has been removed. Use `service_endpoints` with a set of service names instead, for example `service_endpoints = [\"Microsoft.Storage\"]`. Locations are no longer configurable because Azure expands service-endpoint locations implicitly, which caused perpetual drift."
  }
}

variable "sharing_scope" {
  type        = string
  default     = null
  description = <<DESCRIPTION
(Optional) The sharing scope for the subnet. Possible values are `DelegatedServices` and `Tenant`. Defaults to `DelegatedServices`.
DESCRIPTION

  validation {
    condition     = var.sharing_scope != null ? can(regex("^(DelegatedServices|Tenant)$", var.sharing_scope)) : true
    error_message = "sharing_scope must be one of DelegatedServices or Tenant."
  }
}

variable "timeouts" {
  type = object({
    create = optional(string, "30m")
    read   = optional(string, "5m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default     = {}
  description = "Timeouts for the resource operations"
}

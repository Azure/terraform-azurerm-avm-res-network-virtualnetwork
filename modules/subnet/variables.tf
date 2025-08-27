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
(Optional) The address prefix for the subnet. One of `address_prefix` or `address_prefixes` must be supplied.
DESCRIPTION
}

variable "address_prefixes" {
  type        = list(string)
  default     = null
  description = <<DESCRIPTION
(Optional) The address prefixes for the subnet. You can supply more than one address prefix. One of `address_prefix` or `address_prefixes` must be supplied.
DESCRIPTION

  validation {
    condition     = var.address_prefixes == null ? var.address_prefix != null : length(var.address_prefixes) > 0 && var.address_prefix == null
    error_message = "One of `address_prefix` or `address_prefixes` must be supplied."
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
DESCRIPTION
  nullable    = false

  validation {
    condition     = can(regex("^(Disabled|Enabled|NetworkSecurityGroupEnabled|RouteTableEnabled)$", var.private_endpoint_network_policies))
    error_message = "private_endpoint_network_policies must be one of Disabled, Enabled, NetworkSecurityGroupEnabled, or RouteTableEnabled."
  }
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
    error_message_regex  = optional(list(string), ["ReferencedResourceNotProvisioned"])
    interval_seconds     = optional(number, 10)
    max_interval_seconds = optional(number, 180)
    multiplier           = optional(number, 1.5)
    randomization_factor = optional(number, 0.5)
  })
  default     = {}
  description = "Retry configuration for the resource operations"
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
  type        = list(string)
  default     = null
  description = <<DESCRIPTION
DEPRECATED: (Optional) A set of service endpoints to associate with the subnet. Changing this forces a new resource to be created.

Use `var.service_endpoints_with_location` instead, which allows specifying locations for the service endpoints.
DESCRIPTION

  validation {
    error_message = "Service endpoints must be unique."
    condition     = var.service_endpoints != null ? length(var.service_endpoints) == length(toset(var.service_endpoints)) : true
  }
}

variable "service_endpoints_with_location" {
  type = list(object({
    service   = string
    locations = optional(list(string), ["*"])
  }))
  default     = null
  description = <<DESCRIPTION
(Optional) A set of service endpoints with location restrictions to associate with the subnet. Cannot be used together with `service_endpoints`. Each service endpoint is an object with the following properties:
- `service` - (Required) The service name. Changing this forces a new resource to be created.
- `locations` - (Optional) A set of Azure region names where the service endpoint should apply. Default is `["*"]`, which means the service endpoint applies to all regions. If you want to restrict the service endpoint to specific regions, you can provide a set of region names. Changing this forces a new resource to be created.
DESCRIPTION

  validation {
    condition     = !(var.service_endpoints != null && var.service_endpoints_with_location != null)
    error_message = "Cannot specify both `service_endpoints` and `service_endpoints_with_location`. Use only `service_endpoints_with_location` for location support."
  }
  validation {
    error_message = "Locations values must be unique"
    condition     = var.service_endpoints_with_location != null ? alltrue([for endpoint in var.service_endpoints_with_location : length(toset(endpoint.locations)) == length(endpoint.locations)]) : true
  }
  validation {
    error_message = "Service names must be unique"
    condition     = var.service_endpoints_with_location != null ? length([for endpoint in var.service_endpoints_with_location : endpoint.service]) == length(toset([for endpoint in var.service_endpoints_with_location : endpoint.service])) : true
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

variable "name" {
  type        = string
  description = "The name of the Azure Virtual Network Peering"
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = <<DESCRIPTION
  (Required) The local Virtual Network, into which the peering will be created and that will be peered with the optional reverse peering.
  DESCRIPTION
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", var.parent_id))
    error_message = "The parent_id must be a valid Virtual Network resource ID"
  }
}

variable "remote_virtual_network_id" {
  type        = string
  description = <<DESCRIPTION
  (Required) The Remote Virtual Network, which will be peered to and the optional reverse peering will be created in.
  DESCRIPTION
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", var.remote_virtual_network_id))
    error_message = "The remote_virtual_network_id must be a valid Virtual Network resource ID"
  }
}

variable "allow_forwarded_traffic" {
  type        = bool
  default     = false
  description = "Allow forwarded traffic between the virtual networks"
  nullable    = false
}

variable "allow_gateway_transit" {
  type        = bool
  default     = false
  description = "Allow gateway transit between the virtual networks"
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    virtual_networks_virtual_network_peerings = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
(Optional) Peering body property paths (dot notation, relative to the request body) whose changes the `azapi` provider should ignore after creation, letting an out-of-band controller own those properties without producing perpetual `terraform plan` drift.

- `virtual_networks_virtual_network_peerings` - The list of ignored body paths, applied to every peering resource this submodule manages.

Notes:
- Paths use dot notation and are relative to the peering request body. Individual list items cannot be targeted; ignore the whole list property instead.
- This is a write-only argument stored in provider-private state, so changes to it take effect only after an `apply` (a non-empty value requires Terraform >= 1.11).
- While a path is ignored, configuration changes at that path are not sent to Azure until the path is removed from this list.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for path in var.ignore_body_changes.virtual_networks_virtual_network_peerings : length(trimspace(path)) > 0])
    error_message = "Every ignore_body_changes.virtual_networks_virtual_network_peerings entry must be a non-empty body path. Paths are relative to the peering request body and use dot notation."
  }
}

variable "allow_virtual_network_access" {
  type        = bool
  default     = true
  description = "Allow access from the local virtual network to the remote virtual network"
  nullable    = false
}

variable "create_reverse_peering" {
  type        = bool
  default     = false
  description = "Create a reverse peering from the remote virtual network to the local virtual network"
  nullable    = false
}

variable "do_not_verify_remote_gateways" {
  type        = bool
  default     = false
  description = "Do not verify remote gateways for the virtual network peering"
  nullable    = false
}

variable "enable_only_ipv6_peering" {
  type        = bool
  default     = false
  description = "Enable only IPv6 peering for the virtual network peering"
  nullable    = false
}

variable "local_peered_address_spaces" {
  type = list(object({
    address_prefix = string
  }))
  default     = []
  description = "The address space of the local virtual network to peer. Only relevant if peer_complete_vnets is false"

  validation {
    condition     = alltrue([for a in(var.local_peered_address_spaces == null ? [] : var.local_peered_address_spaces) : can(cidrhost(a.address_prefix, 0))])
    error_message = "Each `address_prefix` in `local_peered_address_spaces` must be a valid CIDR block, for example \"10.0.0.0/24\"."
  }
}

variable "local_peered_subnets" {
  type = list(object({
    subnet_name = string
  }))
  default     = []
  description = "The subnets of the local virtual network to peer. Only relevant if peer_complete_vnets is false"
}

variable "peer_complete_vnets" {
  type        = bool
  default     = true
  description = "Peer complete virtual networks for the virtual network peering"
  nullable    = false

  validation {
    condition = var.peer_complete_vnets || (!var.peer_complete_vnets && (
      (length(var.local_peered_address_spaces == null ? [] : var.local_peered_address_spaces) > 0 && length(var.remote_peered_address_spaces == null ? [] : var.remote_peered_address_spaces) > 0)
      ||
      ((length(var.local_peered_subnets == null ? [] : var.local_peered_subnets) > 0 && length(var.remote_peered_subnets == null ? [] : var.remote_peered_subnets) > 0))
    ))
    error_message = "At least one of peered_address_spaces or peered_subnets must be set when peer_complete_vnets is false"
  }
}

variable "remote_peered_address_spaces" {
  type = list(object({
    address_prefix = string
  }))
  default     = []
  description = "The address space of the remote virtual network to peer. Only relevant if peer_complete_vnets is false"

  validation {
    condition     = alltrue([for a in(var.remote_peered_address_spaces == null ? [] : var.remote_peered_address_spaces) : can(cidrhost(a.address_prefix, 0))])
    error_message = "Each `address_prefix` in `remote_peered_address_spaces` must be a valid CIDR block, for example \"10.0.0.0/24\"."
  }
}

variable "remote_peered_subnets" {
  type = list(object({
    subnet_name = string
  }))
  default     = []
  description = "The subnets of the remote virtual network to peer. Only relevant if peer_complete_vnets is false"
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["ReferencedResourceNotProvisioned"])
    interval_seconds     = optional(number, 10)
    max_interval_seconds = optional(number, 180)
  })
  default     = {}
  description = "Retry configuration for the resource operations"
}

variable "resource_types" {
  type = object({
    network_virtual_networks_virtual_network_peerings = optional(string, "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the peering submodule.

- `network_virtual_networks_virtual_network_peerings` - Resource type and API version for virtual network peerings.
DESCRIPTION
  nullable    = false
}

variable "reverse_allow_forwarded_traffic" {
  type        = bool
  default     = false
  description = "Allow forwarded traffic for the reverse peering"
  nullable    = false
}

variable "reverse_allow_gateway_transit" {
  type        = bool
  default     = false
  description = "Allow gateway transit for the reverse peering"
  nullable    = false
}

variable "reverse_allow_virtual_network_access" {
  type        = bool
  default     = true
  description = "Allow access from the remote virtual network to the local virtual network for the reverse peering"
  nullable    = false
}

variable "reverse_do_not_verify_remote_gateways" {
  type        = bool
  default     = false
  description = "Do not verify remote gateways for the reverse peering"
  nullable    = false
}

variable "reverse_enable_only_ipv6_peering" {
  type        = bool
  default     = false
  description = "Enable only IPv6 peering for the reverse peering"
  nullable    = false
}

variable "reverse_local_peered_address_spaces" {
  type = list(object({
    address_prefix = string
  }))
  default     = []
  description = "The address space of the remote virtual network to peer. Only relevant if reverse_peer_complete_vnets is false"

  validation {
    condition     = alltrue([for a in(var.reverse_local_peered_address_spaces == null ? [] : var.reverse_local_peered_address_spaces) : can(cidrhost(a.address_prefix, 0))])
    error_message = "Each `address_prefix` in `reverse_local_peered_address_spaces` must be a valid CIDR block, for example \"10.0.0.0/24\"."
  }
}

variable "reverse_local_peered_subnets" {
  type = list(object({
    subnet_name = string
  }))
  default     = []
  description = "The subnets of the local remote network to peer. Only relevant if reverse_peer_complete_vnets is false"
}

variable "reverse_name" {
  type        = string
  default     = null
  description = "The name of the reverse peering"
}

variable "reverse_peer_complete_vnets" {
  type        = bool
  default     = true
  description = "Peer complete virtual networks for the reverse peering"
  nullable    = false

  validation {
    condition = var.reverse_peer_complete_vnets || (var.create_reverse_peering && !var.reverse_peer_complete_vnets && (
      (length(var.reverse_local_peered_address_spaces == null ? [] : var.reverse_local_peered_address_spaces) > 0 && length(var.reverse_remote_peered_address_spaces == null ? [] : var.reverse_remote_peered_address_spaces) > 0)
      ||
      (length(var.reverse_local_peered_subnets == null ? [] : var.reverse_local_peered_subnets) > 0 && length(var.reverse_remote_peered_subnets == null ? [] : var.reverse_remote_peered_subnets) > 0)
    ))
    error_message = "At least one of reverse_peered_address_spaces or reverse_peered_subnets must be set when reverse_peer_complete_vnets is false"
  }
}

variable "reverse_remote_peered_address_spaces" {
  type = list(object({
    address_prefix = string
  }))
  default     = []
  description = "The address space of the local virtual network to peer. Only relevant if reverse_peer_complete_vnets is false"

  validation {
    condition     = alltrue([for a in(var.reverse_remote_peered_address_spaces == null ? [] : var.reverse_remote_peered_address_spaces) : can(cidrhost(a.address_prefix, 0))])
    error_message = "Each `address_prefix` in `reverse_remote_peered_address_spaces` must be a valid CIDR block, for example \"10.0.0.0/24\"."
  }
}

variable "reverse_remote_peered_subnets" {
  type = list(object({
    subnet_name = string
  }))
  default     = []
  description = "The subnets of the remote local network to peer. Only relevant if reverse_peer_complete_vnets is false"
}

variable "reverse_use_remote_gateways" {
  type        = bool
  default     = false
  description = "Use remote gateways for the reverse peering"
  nullable    = false
}

variable "sync_remote_address_space_enabled" {
  type        = bool
  default     = false
  description = "Synchronize the address space of the remote virtual network with the local virtual network peering if the remote address space is updated. Defaults to `false`"
  nullable    = false
}

variable "sync_remote_address_space_triggers" {
  type        = any
  default     = null
  description = "A value, when changed, will trigger the remote address space to be synced again. This can be used to force a re-sync of the remote address space if needed."

  validation {
    condition     = !var.sync_remote_address_space_enabled || (var.sync_remote_address_space_enabled && var.sync_remote_address_space_triggers != null)
    error_message = "sync_remote_address_space_triggers must be set when sync_remote_address_space_enabled is true"
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

variable "use_remote_gateways" {
  type        = bool
  default     = false
  description = "Use remote gateways for the virtual network peering"
  nullable    = false
}

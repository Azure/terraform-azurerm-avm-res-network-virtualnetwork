variable "name" {
  type        = string
  description = "The name of the Azure Virtual Network Peering"
  nullable    = false
}

variable "remote_virtual_network" {
  type = object({
    resource_id = string
  })
  description = <<DESCRIPTION
  (Required) The Remote Virtual Network, which will be peered to and the optional reverse peering will be created in.

  - resource_id - The ID of the Virtual Network.
  DESCRIPTION
  nullable    = false
}

variable "virtual_network" {
  type = object({
    resource_id = string
  })
  description = <<DESCRIPTION
  (Required) The local Virtual Network, into which the peering will be created and that will be peered with the optional reverse peering.

  - resource_id - The ID of the Virtual Network.
  DESCRIPTION
  nullable    = false
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
}

variable "remote_peered_subnets" {
  type = list(object({
    subnet_name = string
  }))
  default     = []
  description = "The subnets of the remote virtual network to peer. Only relevant if peer_complete_vnets is false"
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

variable "subscription_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
  (Optional) The subscription ID to use for the feature registration.
DESCRIPTION
}

variable "use_remote_gateways" {
  type        = bool
  default     = false
  description = "Use remote gateways for the virtual network peering"
  nullable    = false
}

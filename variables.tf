variable "resource_group_name" {
  type        = string
  description = <<DESCRIPTION
The name of the resource group where the resources will be deployed.

Example usage:
resource_group_name = "myResourceGroup"
DESCRIPTION
}

variable "virtual_network_address_space" {
  type        = list(string)
  description = <<DESCRIPTION
  The address space used by the virtual network. You can supply more than one address space.
  Example usage:

  virtual_network_address_space = ["10.0.0.0/16", "10.1.0.0/16"]
  DESCRIPTION
  nullable    = false

  validation {
    condition     = length(var.virtual_network_address_space) > 0
    error_message = "Please provide at least one CIDR as address space."
  }
}

variable "vnet_location" {
  type        = string
  description = <<DESCRIPTION
  The location/region where the virtual network is created. Changing this forces a new resource to be created

 Example usage:
 vnet_location = "eastus"
 DESCRIPTION
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories_and_groups                = optional(set(string), ["VMProtectionAlerts"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of parameters required to deploy diagnostic settings

  Example usage:
 diagnostic_settings = {
  setting1 = {
    log_analytics_destination_type = "Dedicated"
    workspace_resource_id = "logAnalyticsWorkspaceResourceId"
  }
}
DESCRIPTION 
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
Controls whether or not telemetry is enabled for the module. 
For more information, see https://aka.ms/avm/telemetry.
If it is set to false, then no telemetry will be collected.

Example usage:
enable_telemetry = false
DESCRIPTION
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")


  })
  default     = {}
  description = <<DESCRIPTION
  The lock level to apply to the Virtual Network. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
  Example usage:
  name = "test-lock"
  kind = "ReadOnly"
DESCRIPTION
  nullable    = false

  validation {
    condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
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
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of parameters required to deploy role assignments

 Example usage:
 role_assignments = {
  assignment1 = {
    role_definition_id_or_name = "Contributor"
    principal_id = "servicePrincipalId"
  }
}
DESCRIPTION
}

variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
    nat_gateway = optional(object({
      id = string
    }))
    network_security_group = optional(object({
      id = string
    }))
    private_endpoint_network_policies_enabled     = optional(bool, true)
    private_link_service_network_policies_enabled = optional(bool, true)
    route_table = optional(object({
      id = string
    }))
    service_endpoints           = optional(set(string))
    service_endpoint_policy_ids = optional(set(string))
    delegations = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string))
      })
    })))
  }))
  default     = {}
  description = <<DESCRIPTION
  Subnets to create. Specifies the configuration for each subnet.

  Example usage:
  subnets = {
  subnet1 = {
    address_prefixes = ["10.0.1.0/24"]
    nat_gateway = null
    network_security_group = null
    route_table = null
    service_endpoints = ["Microsoft.Storage"]
  }
  DESCRIPTION
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = <<DESCRIPTION
  The tags to associate with your network and subnets.
 Example usage:
 tags = {
  environment = "production"
  project = "myProject"
}
DESCRIPTION
}

variable "tracing_tags_enabled" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
  Whether to enable tracing tags generated by BridgeCrew Yor
  Example usage:
  tracing_tags_enabled = true
  DESCRIPTION
}

variable "tracing_tags_prefix" {
  type        = string
  default     = "avm_"
  description = <<DESCRIPTION
  Default prefix for generated tracing tags.

 Example usage:
 tracing_tags_prefix = "customPrefix_"
 DESCRIPTION
}

variable "virtual_network_ddos_protection_plan" {
  type = object({
    id     = string
    enable = bool
  })
  default     = null
  description = <<DESCRIPTION
  AzureNetwork DDoS Protection Plan.

Example usage:
virtual_network_ddos_protection_plan = {
  id = "ddosProtectionPlanId"
  enable = true
}
DESCRIPTION
}

variable "virtual_network_dns_servers" {
  type = object({
    dns_servers = list(string)
  })
  default     = null
  description = <<DESCRIPTION
  (Optional) List of IP addresses of DNS servers.

 Example usage:
 virtual_network_dns_servers = {
 dns_servers = ["8.8.8.8", "8.8.4.4"]
}
DESCRIPTION
}

variable "vnet_name" {
  type        = string
  default     = "acctvnet"
  description = <<DESCRIPTION
The name of the virtual network to create.

Example usage:
vnet_name = "myVnet"
DESCRIPTION
}

variable "vnet_peering_config" {
  type = map(object({
    remote_vnet_id          = string
    allow_forwarded_traffic = bool
    allow_gateway_transit   = bool
    use_remote_gateways     = bool
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of virtual network peering configurations. Each entry specifies a remote virtual network by ID and includes settings for traffic forwarding, gateway transit, and remote gateways usage."
  Example usage:
  vnet_peering_config = {
  peering1 = {
    remote_vnet_id          = "remoteVnetId"
    allow_forwarded_traffic = true
    allow_gateway_transit   = false
    use_remote_gateways     = false
  }
}
DESCRIPTION
}

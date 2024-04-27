variable "location" {
  type        = string
  description = <<DESCRIPTION
The location/region where the virtual network is created. Changing this forces a new resource to be created.
DESCRIPTION
}

variable "resource_group_name" {
  type        = string
  description = <<DESCRIPTION
The name of the resource group where the resources will be deployed.
DESCRIPTION
}

variable "virtual_network_address_space" {
  type        = list(string)
  description = " (Required) The address space that is used the virtual network. You can supply more than one address space."
  nullable    = false

  validation {
    condition     = length(var.virtual_network_address_space) > 0
    error_message = "Please provide at least one cidr as address space."
  }
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
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
  Map of diagnostic setting configurations
  DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetry.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "existing_parent_resource" {
  description = "If supplied, this allows subnets to be created against an existing vnet."
  type = object({
    name = string
  })
  default = null
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:
  
  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "name" {
  type        = string
  default     = "acctvnet"
  description = <<DESCRIPTION
The name of the virtual network to create.
DESCRIPTION
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
  nullable    = false
  description = <<DESCRIPTION
  A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
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
}


variable "subnets" {
  type = map(object(
    {
      address_prefixes = list(string) # (Required) The address prefixes to use for the subnet.
      nat_gateway = optional(object({
        id = string # (Required) The ID of the NAT Gateway which should be associated with the Subnet. Changing this forces a new resource to be created.
      }))
      network_security_group = optional(object({
        id = string # (Required) The ID of the Network Security Group which should be associated with the Subnet. Changing this forces a new association to be created.
      }))
      private_endpoint_network_policies_enabled     = optional(bool, true) # (Optional) Enable or Disable network policies for the private endpoint on the subnet. Setting this to `true` will **Enable** the policy and setting this to `false` will **Disable** the policy. Defaults to `true`.
      private_link_service_network_policies_enabled = optional(bool, true) # (Optional) Enable or Disable network policies for the private link service on the subnet. Setting this to `true` will **Enable** the policy and setting this to `false` will **Disable** the policy. Defaults to `true`.
      route_table = optional(object({
        id = string # (Required) The ID of the Route Table which should be associated with the Subnet. Changing this forces a new association to be created.
      }))
      service_endpoints           = optional(set(string)) # (Optional) The list of Service endpoints to associate with the subnet. Possible values include: `Microsoft.AzureActiveDirectory`, `Microsoft.AzureCosmosDB`, `Microsoft.ContainerRegistry`, `Microsoft.EventHub`, `Microsoft.KeyVault`, `Microsoft.ServiceBus`, `Microsoft.Sql`, `Microsoft.Storage` and `Microsoft.Web`.
      service_endpoint_policy_ids = optional(set(string)) # (Optional) The list of IDs of Service Endpoint Policies to associate with the subnet.
      delegations = optional(list(
        object(
          {
            name = string # (Required) A name for this delegation.
            service_delegation = object({
              name    = string                 # (Required) The name of service to delegate to. Possible values include `Microsoft.ApiManagement/service`, `Microsoft.AzureCosmosDB/clusters`, `Microsoft.BareMetal/AzureVMware`, `Microsoft.BareMetal/CrayServers`, `Microsoft.Batch/batchAccounts`, `Microsoft.ContainerInstance/containerGroups`, `Microsoft.ContainerService/managedClusters`, `Microsoft.Databricks/workspaces`, `Microsoft.DBforMySQL/flexibleServers`, `Microsoft.DBforMySQL/serversv2`, `Microsoft.DBforPostgreSQL/flexibleServers`, `Microsoft.DBforPostgreSQL/serversv2`, `Microsoft.DBforPostgreSQL/singleServers`, `Microsoft.HardwareSecurityModules/dedicatedHSMs`, `Microsoft.Kusto/clusters`, `Microsoft.Logic/integrationServiceEnvironments`, `Microsoft.MachineLearningServices/workspaces`, `Microsoft.Netapp/volumes`, `Microsoft.Network/managedResolvers`, `Microsoft.Orbital/orbitalGateways`, `Microsoft.PowerPlatform/vnetaccesslinks`, `Microsoft.ServiceFabricMesh/networks`, `Microsoft.Sql/managedInstances`, `Microsoft.Sql/servers`, `Microsoft.StoragePool/diskPools`, `Microsoft.StreamAnalytics/streamingJobs`, `Microsoft.Synapse/workspaces`, `Microsoft.Web/hostingEnvironments`, `Microsoft.Web/serverFarms`, `NGINX.NGINXPLUS/nginxDeployments` and `PaloAltoNetworks.Cloudngfw/firewalls`.
              actions = optional(list(string)) # (Optional) A list of Actions which should be delegated. This list is specific to the service to delegate to. Possible values include `Microsoft.Network/networkinterfaces/*`, `Microsoft.Network/virtualNetworks/subnets/action`, `Microsoft.Network/virtualNetworks/subnets/join/action`, `Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action` and `Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action`.
            })
          }
        )
      ))
    }
  ))
  default     = {} # Set the default value to an empty map
  description = <<DESCRIPTION
The subnets to create
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}


variable "tracing_tags_enabled" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
Whether enable tracing tags that generated by BridgeCrew Yor.
DESCRIPTION
  nullable    = false
}

variable "tracing_tags_prefix" {
  type        = string
  default     = "avm_"
  description = <<DESCRIPTION
Default prefix for generated tracing tags.
DESCRIPTION
  nullable    = false
}

variable "virtual_network_ddos_protection_plan" {
  type = object({
    id     = string #  (Required) The ID of DDoS Protection Plan.
    enable = bool   # (Required) Enable/disable DDoS Protection Plan on Virtual Network.
  })
  default     = null
  description = "AzureNetwork DDoS Protection Plan."
}

variable "virtual_network_dns_servers" {
  type = object({
    dns_servers = list(string)
  })
  default     = null
  description = "(Optional) List of IP addresses of DNS servers"
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
A map of virtual network peering configurations. Each entry specifies a remote virtual network by ID and includes settings for traffic forwarding, gateway transit, and remote gateways usage.
DESCRIPTION
}

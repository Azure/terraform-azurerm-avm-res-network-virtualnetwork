variable "address_space" {
  type        = list(string)
  default     = null
  description = "(Optional) The address space that is used the virtual network. You can supply more than one address space.  If null, existing_virtual_network must be supplied."
}

variable "ddos_protection_plan" {
  type = object({
    id     = string
    enable = bool
  })
  default     = null
  description = <<DESCRIPTION
Specifies an AzureNetwork DDoS Protection Plan.

- `id`: The ID of the DDoS Protection Plan. (Required)
- `enable`: Enables or disables the DDoS Protection Plan on the Virtual Network. (Required)
DESCRIPTION
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

variable "dns_servers" {
  type = object({
    dns_servers = list(string)
  })
  default     = null
  description = <<DESCRIPTION
(Optional) Specifies a list of IP addresses representing DNS servers.

- `dns_servers`: List of IP addresses of DNS servers.
DESCRIPTION
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

variable "existing_virtual_network" {
  type = object({
    resource_id = string
  })
  default     = null
  description = <<DESCRIPTION
  (Optional) Optionally allows an existing vnet to be supplied, into which subnets can be created.

  - resource_id: The resource ID of the existing virtual network. Changing this forces new subnet resources to be created.

  Example:

  ```terraform
  module "vnet" {
    # ...other parameters

    existing_virtual_network = {
      resource_id = azurerm_virtual_network.this.id
    }
    subnets = local.subnets
  }
  ```

  The advantage of doing so is this encapsulates the resource_id value, which is "known after apply", in an object.
  The object itself can be easily found out if it is null or not, which allows Terraform to make an exact plan 
  of deployment during the "plan stage".

  Reference the AVM guidance: https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tfnfr11---category-code-style---null-comparison-toggle
  DESCRIPTION
}

variable "location" {
  type        = string
  default     = null
  description = <<DESCRIPTION
(Optional) The location/region where the virtual network is created. Changing this forces a new resource to be created. 

This is not required if supplying an existing virtual network resource id.
DESCRIPTION
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  (Optional) Controls the Resource Lock configuration for this resource. The following properties can be specified:
  
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
  default     = null
  description = <<DESCRIPTION
(Optional) The name of the virtual network to create.  If null, existing_virtual_network must be supplied.
DESCRIPTION
}

variable "peerings" {
  type = map(object({
    name                                 = string
    remote_virtual_network_resource_id   = string
    allow_forwarded_traffic              = optional(bool, false)
    allow_gateway_transit                = optional(bool, false)
    allow_virtual_network_access         = optional(bool, true)
    use_remote_gateways                  = optional(bool, false)
    create_reverse_peering               = optional(bool, false)
    reverse_name                         = optional(string)
    reverse_allow_forwarded_traffic      = optional(bool, false)
    reverse_allow_gateway_transit        = optional(bool, false)
    reverse_allow_virtual_network_access = optional(bool, true)
    reverse_use_remote_gateways          = optional(bool, false)

  }))
  default     = {}
  description = <<DESCRIPTION
(Optional) A map of virtual network peering configurations. Each entry specifies a remote virtual network by ID and includes settings for traffic forwarding, gateway transit, and remote gateways usage.

- `name`: The name of the virtual network peering configuration.
- `remote_virtual_network_resource_id`: The resource ID of the remote virtual network.
- `allow_forwarded_traffic`: (Optional) Enables forwarded traffic between the virtual networks. Defaults to false.
- `allow_gateway_transit`: (Optional) Enables gateway transit for the virtual networks. Defaults to false.
- `allow_virtual_network_access`: (Optional) Enables access from the local virtual network to the remote virtual network. Defaults to true.
- `use_remote_gateways`: (Optional) Enables the use of remote gateways for the virtual networks. Defaults to false.
- `create_reverse_peering`: (Optional) Creates the reverse peering to form a complete peering.
- `reverse_name`: (Optional) If you have selected `create_reverse_peering`, then this name will be used for the reverse peer.
- `reverse_allow_forwarded_traffic`: (Optional) If you have selected `create_reverse_peering`, enables forwarded traffic between the virtual networks. Defaults to false.
- `reverse_allow_gateway_transit`: (Optional) If you have selected `create_reverse_peering`, enables gateway transit for the virtual networks. Defaults to false.
- `reverse_allow_virtual_network_access`: (Optional) If you have selected `create_reverse_peering`, enables access from the local virtual network to the remote virtual network. Defaults to true.
- `reverse_use_remote_gateways`: (Optional) If you have selected `create_reverse_peering`, enables the use of remote gateways for the virtual networks. Defaults to false.

DESCRIPTION
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  default     = null
  description = <<DESCRIPTION
(Optional) The name of the resource group where the resources will be deployed. 

This is not requied if supplying an existing virtual network resource id.
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
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  (Optional) A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
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

variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
    name             = string
    nat_gateway = optional(object({
      id = string
    }))
    network_security_group = optional(object({
      id = string
    }))
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    route_table = optional(object({
      id = string
    }))
    service_endpoint_policy_ids = optional(set(string))
    service_endpoints           = optional(set(string))
    delegation = optional(list(object({
      name = string
      service_delegation = object({
        name = string
      })
    })))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  default     = {} # Set the default value to an empty map
  description = <<DESCRIPTION
(Optional) A map of subnets to create

 - `address_prefixes` - (Required) The address prefixes to use for the subnet.
 - `enforce_private_link_endpoint_network_policies` - 
 - `enforce_private_link_service_network_policies` - 
 - `name` - (Required) The name of the subnet. Changing this forces a new resource to be created.
 - `private_endpoint_network_policies` - (Optional) Enable or Disable network policies for the private endpoint on the subnet. Possible values are `Disabled`, `Enabled`, `NetworkSecurityGroupEnabled` and `RouteTableEnabled`. Defaults to `Enabled`.
 - `private_link_service_network_policies_enabled` - (Optional) Enable or Disable network policies for the private link service on the subnet. Setting this to `true` will **Enable** the policy and setting this to `false` will **Disable** the policy. Defaults to `true`.
 - `resource_group_name` - (Required) The name of the resource group in which to create the subnet. This must be the resource group that the virtual network resides in. Changing this forces a new resource to be created.
 - `service_endpoint_policy_ids` - (Optional) The list of IDs of Service Endpoint Policies to associate with the subnet.
 - `service_endpoints` - (Optional) The list of Service endpoints to associate with the subnet. Possible values include: `Microsoft.AzureActiveDirectory`, `Microsoft.AzureCosmosDB`, `Microsoft.ContainerRegistry`, `Microsoft.EventHub`, `Microsoft.KeyVault`, `Microsoft.ServiceBus`, `Microsoft.Sql`, `Microsoft.Storage`, `Microsoft.Storage.Global` and `Microsoft.Web`.
 - `virtual_network_name` - (Required) The name of the virtual network to which to attach the subnet. Changing this forces a new resource to be created.

 ---
 `delegation` block supports the following:
 - `name` - (Required) A name for this delegation.

 ---
 `nat_gateway` block supports the following:
 - `id` - (Optional) The ID of the NAT Gateway which should be associated with the Subnet. Changing this forces a new resource to be created.

 ---
 `network_security_group` block supports the following:
 - `id` - (Optional) The ID of the Network Security Group which should be associated with the Subnet. Changing this forces a new association to be created.

 ---
 `route_table` block supports the following:
 - `id` - (Optional) The ID of the Route Table which should be associated with the Subnet. Changing this forces a new association to be created.

 ---
 `service_delegation` block supports the following:
 - `actions` - (Optional) A list of Actions which should be delegated. This list is specific to the service to delegate to. Possible values are `Microsoft.Network/networkinterfaces/*`, `Microsoft.Network/publicIPAddresses/join/action`, `Microsoft.Network/publicIPAddresses/read`, `Microsoft.Network/virtualNetworks/read`, `Microsoft.Network/virtualNetworks/subnets/action`, `Microsoft.Network/virtualNetworks/subnets/join/action`, `Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action`, and `Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action`.
 - `name` - (Required) The name of service to delegate to. Possible values are `GitHub.Network/networkSettings`, `Microsoft.ApiManagement/service`, `Microsoft.Apollo/npu`, `Microsoft.App/environments`, `Microsoft.App/testClients`, `Microsoft.AVS/PrivateClouds`, `Microsoft.AzureCosmosDB/clusters`, `Microsoft.BareMetal/AzureHostedService`, `Microsoft.BareMetal/AzureHPC`, `Microsoft.BareMetal/AzurePaymentHSM`, `Microsoft.BareMetal/AzureVMware`, `Microsoft.BareMetal/CrayServers`, `Microsoft.BareMetal/MonitoringServers`, `Microsoft.Batch/batchAccounts`, `Microsoft.CloudTest/hostedpools`, `Microsoft.CloudTest/images`, `Microsoft.CloudTest/pools`, `Microsoft.Codespaces/plans`, `Microsoft.ContainerInstance/containerGroups`, `Microsoft.ContainerService/managedClusters`, `Microsoft.ContainerService/TestClients`, `Microsoft.Databricks/workspaces`, `Microsoft.DBforMySQL/flexibleServers`, `Microsoft.DBforMySQL/servers`, `Microsoft.DBforMySQL/serversv2`, `Microsoft.DBforPostgreSQL/flexibleServers`, `Microsoft.DBforPostgreSQL/serversv2`, `Microsoft.DBforPostgreSQL/singleServers`, `Microsoft.DelegatedNetwork/controller`, `Microsoft.DevCenter/networkConnection`, `Microsoft.DocumentDB/cassandraClusters`, `Microsoft.Fidalgo/networkSettings`, `Microsoft.HardwareSecurityModules/dedicatedHSMs`, `Microsoft.Kusto/clusters`, `Microsoft.LabServices/labplans`, `Microsoft.Logic/integrationServiceEnvironments`, `Microsoft.MachineLearningServices/workspaces`, `Microsoft.Netapp/volumes`, `Microsoft.Network/dnsResolvers`, `Microsoft.Network/managedResolvers`, `Microsoft.Network/fpgaNetworkInterfaces`, `Microsoft.Network/networkWatchers.`, `Microsoft.Network/virtualNetworkGateways`, `Microsoft.Orbital/orbitalGateways`, `Microsoft.PowerPlatform/enterprisePolicies`, `Microsoft.PowerPlatform/vnetaccesslinks`, `Microsoft.ServiceFabricMesh/networks`, `Microsoft.ServiceNetworking/trafficControllers`, `Microsoft.Singularity/accounts/networks`, `Microsoft.Singularity/accounts/npu`, `Microsoft.Sql/managedInstances`, `Microsoft.Sql/managedInstancesOnebox`, `Microsoft.Sql/managedInstancesStage`, `Microsoft.Sql/managedInstancesTest`, `Microsoft.Sql/servers`, `Microsoft.StoragePool/diskPools`, `Microsoft.StreamAnalytics/streamingJobs`, `Microsoft.Synapse/workspaces`, `Microsoft.Web/hostingEnvironments`, `Microsoft.Web/serverFarms`, `NGINX.NGINXPLUS/nginxDeployments`, `PaloAltoNetworks.Cloudngfw/firewalls`, `Qumulo.Storage/fileSystems`, and `Oracle.Database/networkAttachments`.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Subnet.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Subnet.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Subnet.
 - `update` - (Defaults to 30 minutes) Used when updating the Subnet.
 
DESCRIPTION
}

variable "subscription_id" {
  type        = string
  default     = null
  description = "(Optional) Subscription ID passed in by an external process.  If this is not supplied, then the configuration either needs to include the subscription ID, or needs to be supplied properties to create the subscription."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

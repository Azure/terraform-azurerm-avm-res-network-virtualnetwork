<!-- BEGIN_TF_DOCS -->
# Azure Verified Module for Azure Virtual Networks

This module provides a generic way to create and manage Azure Virtual Networks (vNets) and their associated resources.

To use this module in your Terraform configuration, you'll need to provide values for the required variables. Here's a basic example:

```
module "azure_vnet" {
  source = "./path_to_this_module"

  address_spaces = ["10.0.0.0/16"]
  vnet_location  = "East US"
  name           = "myVNet"
  resource_group_name = "myResourceGroup"
  // ... other required variables ...
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71.0, < 4.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.71.0, < 4.0)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.5.0, < 4.0)

## Resources

The following resources are used by this module:

- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.subnet-level](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.vnet-level](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_nat_gateway_association.nat_gw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) (resource)
- [azurerm_subnet_network_security_group_association.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) (resource)
- [azurerm_subnet_route_table_association.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_virtual_network_dns_servers.vnet_dns](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_dns_servers) (resource)
- [azurerm_virtual_network_peering.vnet_peering](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) (resource)
- [random_id.telem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The name of the resource group where the resources will be deployed.

Example usage:  
resource\_group\_name = "myResourceGroup"

Type: `string`

### <a name="input_virtual_network_address_space"></a> [virtual\_network\_address\_space](#input\_virtual\_network\_address\_space)

Description:   The address space used by the virtual network. You can supply more than one address space.  
  Example usage:

  virtual\_network\_address\_space = ["10.0.0.0/16", "10.1.0.0/16"]

Type: `list(string)`

### <a name="input_vnet_location"></a> [vnet\_location](#input\_vnet\_location)

Description:   The location/region where the virtual network is created. Changing this forces a new resource to be created

 Example usage:  
 vnet\_location = "eastus"

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description:   A map of parameters required to deploy diagnostic settings

  Example usage:  
 diagnostic\_settings = {  
  setting1 = {  
    log\_analytics\_destination\_type = "Dedicated"  
    workspace\_resource\_id = "logAnalyticsWorkspaceResourceId"
  }
}

Type:

```hcl
map(object({
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
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: Controls whether or not telemetry is enabled for the module.   
For more information, see https://aka.ms/avm/telemetry.  
If it is set to false, then no telemetry will be collected.

Example usage:  
enable\_telemetry = false

Type: `bool`

Default: `true`

### <a name="input_lock"></a> [lock](#input\_lock)

Description:   The lock level to apply to the Virtual Network. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.  
  Example usage:  
  name = "test-lock"  
  kind = "ReadOnly"

Type:

```hcl
object({
    name = optional(string, null)
    kind = optional(string, "None")

  })
```

Default: `{}`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:   A map of parameters required to deploy role assignments

 Example usage:  
 role\_assignments = {  
  assignment1 = {  
    role\_definition\_id\_or\_name = "Contributor"  
    principal\_id = "servicePrincipalId"
  }
}

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_subnets"></a> [subnets](#input\_subnets)

Description:   Subnets to create. Specifies the configuration for each subnet.

  Example usage:  
  subnets = {  
  subnet1 = {  
    address\_prefixes = ["10.0.1.0/24"]  
    nat\_gateway = null  
    network\_security\_group = null  
    route\_table = null  
    service\_endpoints = ["Microsoft.Storage"]
  }

Type:

```hcl
map(object({
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
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description:   The tags to associate with your network and subnets.  
 Example usage:  
 tags = {  
  environment = "production"  
  project = "myProject"
}

Type: `map(any)`

Default: `{}`

### <a name="input_tracing_tags_enabled"></a> [tracing\_tags\_enabled](#input\_tracing\_tags\_enabled)

Description:   Whether to enable tracing tags generated by BridgeCrew Yor  
  Example usage:  
  tracing\_tags\_enabled = true

Type: `bool`

Default: `false`

### <a name="input_tracing_tags_prefix"></a> [tracing\_tags\_prefix](#input\_tracing\_tags\_prefix)

Description:   Default prefix for generated tracing tags.

 Example usage:  
 tracing\_tags\_prefix = "customPrefix\_"

Type: `string`

Default: `"avm_"`

### <a name="input_virtual_network_ddos_protection_plan"></a> [virtual\_network\_ddos\_protection\_plan](#input\_virtual\_network\_ddos\_protection\_plan)

Description:   AzureNetwork DDoS Protection Plan.

Example usage:  
virtual\_network\_ddos\_protection\_plan = {  
  id = "ddosProtectionPlanId"  
  enable = true
}

Type:

```hcl
object({
    id     = string
    enable = bool
  })
```

Default: `null`

### <a name="input_virtual_network_dns_servers"></a> [virtual\_network\_dns\_servers](#input\_virtual\_network\_dns\_servers)

Description:   (Optional) List of IP addresses of DNS servers.

 Example usage:  
 virtual\_network\_dns\_servers = {  
 dns\_servers = ["8.8.8.8", "8.8.4.4"]
}

Type:

```hcl
object({
    dns_servers = list(string)
  })
```

Default: `null`

### <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name)

Description: The name of the virtual network to create.

Example usage:  
vnet\_name = "myVnet"

Type: `string`

Default: `"acctvnet"`

### <a name="input_vnet_peering_config"></a> [vnet\_peering\_config](#input\_vnet\_peering\_config)

Description:   A map of virtual network peering configurations. Each entry specifies a remote virtual network by ID and includes settings for traffic forwarding, gateway transit, and remote gateways usage."  
  Example usage:  
  vnet\_peering\_config = {  
  peering1 = {  
    remote\_vnet\_id          = "remoteVnetId"  
    allow\_forwarded\_traffic = true  
    allow\_gateway\_transit   = false  
    use\_remote\_gateways     = false
  }
}

Type:

```hcl
map(object({
    remote_vnet_id          = string
    allow_forwarded_traffic = bool
    allow_gateway_transit   = bool
    use_remote_gateways     = bool
  }))
```

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_subnets"></a> [subnets](#output\_subnets)

Description: Information about the subnets created in the module.

### <a name="output_vnet_resource"></a> [vnet\_resource](#output\_vnet\_resource)

Description: The Azure Virtual Network resource

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

## AVM Versioning Notice

Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to https://semver.org/
<!-- END_TF_DOCS -->
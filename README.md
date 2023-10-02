<!-- BEGIN_TF_DOCS -->
# Azure Verified Module for Azure Virtual Networks

This module provides a generic way to create and manage Azure Virtual Networks (vNets) and their associated resources.

## Resources Created

-Azure Virtual Network (vNet): A virtual network with the specified configurations.

-Subnets: Subnets within the created virtual network.

-Network Security Group Association: Associates Network Security Groups to the created subnets.

-Route Table Association: Associates Route Tables to the created subnets.

-Management Lock: Applies a management lock to the virtual network if specified.

-Role Assignment: Assigns roles to the virtual network based on the provided configurations.

-Diagnostic Settings: Creates diagnostic settings for the virtual network. Usage

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

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (3.74.0)

- <a name="provider_random"></a> [random](#provider\_random) (3.5.1)

## Resources

The following resources are used by this module:

- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_network_security_group_association.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) (resource)
- [azurerm_subnet_route_table_association.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [random_id.telem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The name of the resource group where the resources will be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_address_space"></a> [address\_space](#input\_address\_space)

Description: The address space that is used by the virtual network.

Type: `string`

Default: `"10.0.0.0/16"`

### <a name="input_address_spaces"></a> [address\_spaces](#input\_address\_spaces)

Description: The list of the address spaces that is used by the virtual network.

Type: `list(string)`

Default: `[]`

### <a name="input_ddos_protection_plan"></a> [ddos\_protection\_plan](#input\_ddos\_protection\_plan)

Description: The set of DDoS protection plan configuration.

Type:

```hcl
object({
    enable = bool
    id     = string
  })
```

Default: `null`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: n/a

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

### <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers)

Description: The DNS servers to be used with vNet.  
If no values are specified, this defaults to Azure DNS.

Type: `list(string)`

Default: `[]`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetry.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: The lock level to apply to the Virtual Network. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.

Type:

```hcl
object({
    name = optional(string, null)
    kind = optional(string, "None")

  })
```

Default: `{}`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the virtual network to create.

Type: `string`

Default: `"acctvnet"`

### <a name="input_nsg_ids"></a> [nsg\_ids](#input\_nsg\_ids)

Description: A map of subnet name to Network Security Group IDs.

Type: `map(string)`

Default: `{}`

### <a name="input_private_link_endpoint_network_policies_enabled"></a> [private\_link\_endpoint\_network\_policies\_enabled](#input\_private\_link\_endpoint\_network\_policies\_enabled)

Description: A map with key (string) `subnet name`, value (bool) `true` or `false` to indicate enable or disable network policies for the private link endpoint on the subnet. Default value is false.

Type: `map(bool)`

Default: `{}`

### <a name="input_private_link_service_network_policies_enabled"></a> [private\_link\_service\_network\_policies\_enabled](#input\_private\_link\_service\_network\_policies\_enabled)

Description: A map with key (string) `subnet name`, value (bool) `true` or `false` to indicate enable or disable network policies for the private link service on the subnet. Default value is false.

Type: `map(bool)`

Default: `{}`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: n/a

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, true)
    condition                              = optional(string, null)
    condition_version                      = optional(string, "2.0")
    delegated_managed_identity_resource_id = optional(string)
  }))
```

Default: `{}`

### <a name="input_route_tables_ids"></a> [route\_tables\_ids](#input\_route\_tables\_ids)

Description: A map of subnet name to Route table ids.

Type: `map(string)`

Default: `{}`

### <a name="input_subnet_delegation"></a> [subnet\_delegation](#input\_subnet\_delegation)

Description: `service_delegation` blocks for `azurerm_subnet` resource, subnet names as keys, list of delegation blocks as value, more details about delegation block could be found at the [document](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet#delegation).

Type:

```hcl
map(list(object({
    name = string
    service_delegation = object({
      name    = string
      actions = optional(list(string))
    })
  })))
```

Default: `{}`

### <a name="input_subnet_names"></a> [subnet\_names](#input\_subnet\_names)

Description: A list of public subnets inside the vNet.

Type: `list(string)`

Default:

```json
[
  "subnet1"
]
```

### <a name="input_subnet_prefixes"></a> [subnet\_prefixes](#input\_subnet\_prefixes)

Description: The address prefix to use for the subnet.

Type: `list(string)`

Default:

```json
[
  "10.0.1.0/24"
]
```

### <a name="input_subnet_service_endpoints"></a> [subnet\_service\_endpoints](#input\_subnet\_service\_endpoints)

Description: A map with key (string) `subnet name`, value (list(string)) to indicate enabled service endpoints on the subnet. Default value is [].

Type: `map(list(string))`

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: The tags to associate with your network and subnets.

Type: `map(any)`

Default: `{}`

### <a name="input_tracing_tags_enabled"></a> [tracing\_tags\_enabled](#input\_tracing\_tags\_enabled)

Description: Whether enable tracing tags that generated by BridgeCrew Yor.

Type: `bool`

Default: `false`

### <a name="input_tracing_tags_prefix"></a> [tracing\_tags\_prefix](#input\_tracing\_tags\_prefix)

Description: Default prefix for generated tracing tags.

Type: `string`

Default: `"avm_"`

### <a name="input_vnet_location"></a> [vnet\_location](#input\_vnet\_location)

Description: The location/region where the virtual network is created. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the newly created vNet

### <a name="output_subnet_address_prefixes"></a> [subnet\_address\_prefixes](#output\_subnet\_address\_prefixes)

Description: The address prefixes of the newly created subnets

### <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids)

Description: The ids of the newly created subnets

### <a name="output_subnet_names"></a> [subnet\_names](#output\_subnet\_names)

Description: The names of the newly created subnets

### <a name="output_vnet_address_space"></a> [vnet\_address\_space](#output\_vnet\_address\_space)

Description: The address space of the newly created vNet

### <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id)

Description: The id of the newly created vNet

### <a name="output_vnet_location"></a> [vnet\_location](#output\_vnet\_location)

Description: The location of the newly created vNet

## Modules

No modules.


<!-- END_TF_DOCS -->
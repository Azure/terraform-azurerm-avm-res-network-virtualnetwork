<!-- BEGIN_TF_DOCS -->
# Azure Virtual Network Subnet Module

This module is used to manage Azure Virtual Network Subnets.

## Features

This module supports managing virtual networks subnets.

The module supports:

- Creating a new subnet
- Associating a network security group with a subnet
- Associating a route table with a subnet
- Associating a service endpoint with a subnet
- Associating a virtual network gateway with a subnet
- Assigning delegations to subnets

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Basic Subnet

This example shows the most basic usage of the module. It creates a new subnet.

```terraform
module "avm-res-network-virtualnetwork-subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  virtual_network = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet"
  }
  address_prefixes = ["10.0.0.0/24"]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (>= 1.13, < 3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (>= 1.13, < 3)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azapi_resource.role_assignment](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.subnet](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_update_resource.allow_deletion_of_ip_prefix_from_subnet](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) (resource)
- [azapi_update_resource.allow_multiple_address_prefixes_on_subnet](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) (resource)
- [azapi_update_resource.enable_shared_vnet](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) (resource)
- [random_uuid.role_assignment](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azapi_resource_list.role_definition](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource_list) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_name"></a> [name](#input\_name)

Description: (Optional) The name of the subnet to create.

Type: `string`

### <a name="input_virtual_network"></a> [virtual\_network](#input\_virtual\_network)

Description:   (Required) The Virtual Network, into which the subnet will be created.

  - resource\_id - The ID of the Virtual Network.

Type:

```hcl
object({
    resource_id = string
  })
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_address_prefix"></a> [address\_prefix](#input\_address\_prefix)

Description:   (Optional) The address prefix for the subnet. One of `address_prefix` or `address_prefixes` must be supplied.

Type: `string`

Default: `null`

### <a name="input_address_prefixes"></a> [address\_prefixes](#input\_address\_prefixes)

Description:   (Optional) The address prefixes for the subnet. You can supply more than one address prefix. One of `address_prefix` or `address_prefixes` must be supplied.

Type: `list(string)`

Default: `null`

### <a name="input_default_outbound_access_enabled"></a> [default\_outbound\_access\_enabled](#input\_default\_outbound\_access\_enabled)

Description: (Optional) Determines whether default outbound internet access is enabled for this subnet. This can only be set at create time.

More details here: https://learn.microsoft.com/en-gb/azure/virtual-network/ip-services/default-outbound-access

Type: `bool`

Default: `false`

### <a name="input_delegation"></a> [delegation](#input\_delegation)

Description: (Optional) A list of delegations to apply to the subnet. Each delegation supports the following:

    - `name` - (Required) A name for this delegation.
    - `service_delegation` - (Required) A block defining the service to delegate to. It supports the
      - `name` - (Required) The name of the service to delegate to.

Type:

```hcl
list(object({
    name = string
    service_delegation = object({
      name = string
    })
  }))
```

Default: `null`

### <a name="input_nat_gateway"></a> [nat\_gateway](#input\_nat\_gateway)

Description: (Optional) The ID of the NAT Gateway to associate with the subnet. Changing this forces a new resource to be created.

Type:

```hcl
object({
    id = string
  })
```

Default: `null`

### <a name="input_network_security_group"></a> [network\_security\_group](#input\_network\_security\_group)

Description: (Optional) The ID of the Network Security Group to associate with the subnet. Changing this forces a new resource to be created.

Type:

```hcl
object({
    id = string
  })
```

Default: `null`

### <a name="input_private_endpoint_network_policies"></a> [private\_endpoint\_network\_policies](#input\_private\_endpoint\_network\_policies)

Description: (Optional) Enable or Disable network policies for the private endpoint on the subnet. Possible values are `Disabled`, `Enabled`, `NetworkSecurityGroupEnabled` and `RouteTableEnabled`. Defaults to `Enabled`.

Type: `string`

Default: `"Enabled"`

### <a name="input_private_link_service_network_policies_enabled"></a> [private\_link\_service\_network\_policies\_enabled](#input\_private\_link\_service\_network\_policies\_enabled)

Description: (Optional) Enable or Disable network policies for the private link service on the subnet. Setting this to `true` will **Enable** the policy and setting this to `false` will **Disable** the policy. Defaults to `true`.

Type: `bool`

Default: `true`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:   (Optional) A map of role assignments to create on the subnet. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

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
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_route_table"></a> [route\_table](#input\_route\_table)

Description: (Optional) The ID of the route table to associate with the subnet.

Type:

```hcl
object({
    id = string
  })
```

Default: `null`

### <a name="input_service_endpoint_policies"></a> [service\_endpoint\_policies](#input\_service\_endpoint\_policies)

Description: (Optional) A set of service endpoint policy IDs to associate with the subnet.

Type:

```hcl
map(object({
    id = string
  }))
```

Default: `null`

### <a name="input_service_endpoints"></a> [service\_endpoints](#input\_service\_endpoints)

Description: (Optional) A set of service endpoints to associate with the subnet. Changing this forces a new resource to be created.

Type: `set(string)`

Default: `null`

### <a name="input_sharing_scope"></a> [sharing\_scope](#input\_sharing\_scope)

Description: (Optional) The sharing scope for the subnet. Possible values are `DelegatedServices` and `Tenant`. Defaults to `DelegatedServices`.

Type: `string`

Default: `null`

### <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id)

Description:   (Optional) The subscription ID to use for the feature registration.

Type: `string`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_application_gateway_ip_configuration_resource_id"></a> [application\_gateway\_ip\_configuration\_resource\_id](#output\_application\_gateway\_ip\_configuration\_resource\_id)

Description: The application gateway ip configurations resource id.

### <a name="output_name"></a> [name](#output\_name)

Description: The resource name of the subnet.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: All attributes of the subnet

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The resource ID of the subnet.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
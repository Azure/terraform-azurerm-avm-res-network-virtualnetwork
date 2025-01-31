<!-- BEGIN_TF_DOCS -->
# Azure Virtual Network Peering Module

This module is used to manage Azure Virtual Network Peerings.

## Features

This module supports managing virtual networks peerings.

The module supports:

- Creating a new peering
- Optionally creating a reverse peering

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Basic Subnet

This example shows the basic usage of the module. It creates a new bi-directional peering.

```terraform
module "avm-res-network-virtualnetwork-subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"

  virtual_network = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroupSpoke/providers/Microsoft.Network/virtualNetworks/myVNetLocal"
  }
  remote_virtual_network = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroupHub/providers/Microsoft.Network/virtualNetworks/myVNetRemote"
  }
  name                                 = "local-to-remote"
  allow_forwarded_traffic              = true
  allow_gateway_transit                = true
  allow_virtual_network_access         = true
  use_remote_gateways                  = false
  create_reverse_peering               = true
  reverse_name                         = "remote-to-local"
  reverse_allow_forwarded_traffic      = false
  reverse_allow_gateway_transit        = false
  reverse_allow_virtual_network_access = true
  reverse_use_remote_gateways          = false
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (>= 1.13, < 3)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (>= 1.13, < 3)

## Resources

The following resources are used by this module:

- [azapi_resource.address_space_peering](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.reverse](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.reverse_address_space_peering](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.reverse_subnet_peering](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.subnet_peering](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.this](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_update_resource.allow_multiple_peering_links_between_vnets](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) (resource)
- [azapi_update_resource.remote_allow_multiple_peering_links_between_vnets](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the Azure Virtual Network Peering

Type: `string`

### <a name="input_remote_virtual_network"></a> [remote\_virtual\_network](#input\_remote\_virtual\_network)

Description:   (Required) The Remote Virtual Network, which will be peered to and the optional reverse peering will be created in.

  - resource\_id - The ID of the Virtual Network.

Type:

```hcl
object({
    resource_id = string
  })
```

### <a name="input_virtual_network"></a> [virtual\_network](#input\_virtual\_network)

Description:   (Required) The local Virtual Network, into which the peering will be created and that will be peered with the optional reverse peering.

  - resource\_id - The ID of the Virtual Network.

Type:

```hcl
object({
    resource_id = string
  })
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_allow_forwarded_traffic"></a> [allow\_forwarded\_traffic](#input\_allow\_forwarded\_traffic)

Description: Allow forwarded traffic between the virtual networks

Type: `bool`

Default: `false`

### <a name="input_allow_gateway_transit"></a> [allow\_gateway\_transit](#input\_allow\_gateway\_transit)

Description: Allow gateway transit between the virtual networks

Type: `bool`

Default: `false`

### <a name="input_allow_virtual_network_access"></a> [allow\_virtual\_network\_access](#input\_allow\_virtual\_network\_access)

Description: Allow access from the local virtual network to the remote virtual network

Type: `bool`

Default: `true`

### <a name="input_create_reverse_peering"></a> [create\_reverse\_peering](#input\_create\_reverse\_peering)

Description: Create a reverse peering from the remote virtual network to the local virtual network

Type: `bool`

Default: `false`

### <a name="input_do_not_verify_remote_gateways"></a> [do\_not\_verify\_remote\_gateways](#input\_do\_not\_verify\_remote\_gateways)

Description: Do not verify remote gateways for the virtual network peering

Type: `bool`

Default: `false`

### <a name="input_enable_only_ipv6_peering"></a> [enable\_only\_ipv6\_peering](#input\_enable\_only\_ipv6\_peering)

Description: Enable only IPv6 peering for the virtual network peering

Type: `bool`

Default: `false`

### <a name="input_local_peered_address_spaces"></a> [local\_peered\_address\_spaces](#input\_local\_peered\_address\_spaces)

Description: The address space of the local virtual network to peer. Only relevant if peer\_complete\_vnets is false

Type:

```hcl
list(object({
    address_prefix = string
  }))
```

Default: `[]`

### <a name="input_local_peered_subnets"></a> [local\_peered\_subnets](#input\_local\_peered\_subnets)

Description: The subnets of the local virtual network to peer. Only relevant if peer\_complete\_vnets is false

Type:

```hcl
list(object({
    subnet_name = string
  }))
```

Default: `[]`

### <a name="input_peer_complete_vnets"></a> [peer\_complete\_vnets](#input\_peer\_complete\_vnets)

Description: Peer complete virtual networks for the virtual network peering

Type: `bool`

Default: `true`

### <a name="input_remote_peered_address_spaces"></a> [remote\_peered\_address\_spaces](#input\_remote\_peered\_address\_spaces)

Description: The address space of the remote virtual network to peer. Only relevant if peer\_complete\_vnets is false

Type:

```hcl
list(object({
    address_prefix = string
  }))
```

Default: `[]`

### <a name="input_remote_peered_subnets"></a> [remote\_peered\_subnets](#input\_remote\_peered\_subnets)

Description: The subnets of the remote virtual network to peer. Only relevant if peer\_complete\_vnets is false

Type:

```hcl
list(object({
    subnet_name = string
  }))
```

Default: `[]`

### <a name="input_reverse_allow_forwarded_traffic"></a> [reverse\_allow\_forwarded\_traffic](#input\_reverse\_allow\_forwarded\_traffic)

Description: Allow forwarded traffic for the reverse peering

Type: `bool`

Default: `false`

### <a name="input_reverse_allow_gateway_transit"></a> [reverse\_allow\_gateway\_transit](#input\_reverse\_allow\_gateway\_transit)

Description: Allow gateway transit for the reverse peering

Type: `bool`

Default: `false`

### <a name="input_reverse_allow_virtual_network_access"></a> [reverse\_allow\_virtual\_network\_access](#input\_reverse\_allow\_virtual\_network\_access)

Description: Allow access from the remote virtual network to the local virtual network for the reverse peering

Type: `bool`

Default: `true`

### <a name="input_reverse_do_not_verify_remote_gateways"></a> [reverse\_do\_not\_verify\_remote\_gateways](#input\_reverse\_do\_not\_verify\_remote\_gateways)

Description: Do not verify remote gateways for the reverse peering

Type: `bool`

Default: `false`

### <a name="input_reverse_enable_only_ipv6_peering"></a> [reverse\_enable\_only\_ipv6\_peering](#input\_reverse\_enable\_only\_ipv6\_peering)

Description: Enable only IPv6 peering for the reverse peering

Type: `bool`

Default: `false`

### <a name="input_reverse_local_peered_address_spaces"></a> [reverse\_local\_peered\_address\_spaces](#input\_reverse\_local\_peered\_address\_spaces)

Description: The address space of the remote virtual network to peer. Only relevant if reverse\_peer\_complete\_vnets is false

Type:

```hcl
list(object({
    address_prefix = string
  }))
```

Default: `[]`

### <a name="input_reverse_local_peered_subnets"></a> [reverse\_local\_peered\_subnets](#input\_reverse\_local\_peered\_subnets)

Description: The subnets of the local remote network to peer. Only relevant if reverse\_peer\_complete\_vnets is false

Type:

```hcl
list(object({
    subnet_name = string
  }))
```

Default: `[]`

### <a name="input_reverse_name"></a> [reverse\_name](#input\_reverse\_name)

Description: The name of the reverse peering

Type: `string`

Default: `null`

### <a name="input_reverse_peer_complete_vnets"></a> [reverse\_peer\_complete\_vnets](#input\_reverse\_peer\_complete\_vnets)

Description: Peer complete virtual networks for the reverse peering

Type: `bool`

Default: `true`

### <a name="input_reverse_remote_peered_address_spaces"></a> [reverse\_remote\_peered\_address\_spaces](#input\_reverse\_remote\_peered\_address\_spaces)

Description: The address space of the local virtual network to peer. Only relevant if reverse\_peer\_complete\_vnets is false

Type:

```hcl
list(object({
    address_prefix = string
  }))
```

Default: `[]`

### <a name="input_reverse_remote_peered_subnets"></a> [reverse\_remote\_peered\_subnets](#input\_reverse\_remote\_peered\_subnets)

Description: The subnets of the remote local network to peer. Only relevant if reverse\_peer\_complete\_vnets is false

Type:

```hcl
list(object({
    subnet_name = string
  }))
```

Default: `[]`

### <a name="input_reverse_use_remote_gateways"></a> [reverse\_use\_remote\_gateways](#input\_reverse\_use\_remote\_gateways)

Description: Use remote gateways for the reverse peering

Type: `bool`

Default: `false`

### <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id)

Description:   (Optional) The subscription ID to use for the feature registration.

Type: `string`

Default: `null`

### <a name="input_use_remote_gateways"></a> [use\_remote\_gateways](#input\_use\_remote\_gateways)

Description: Use remote gateways for the virtual network peering

Type: `bool`

Default: `false`

## Outputs

The following outputs are exported:

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the peering resource

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The resource ID of the peering resource.

### <a name="output_reverse_name"></a> [reverse\_name](#output\_reverse\_name)

Description: The name of the reverse peering resource

### <a name="output_reverse_resource_id"></a> [reverse\_resource\_id](#output\_reverse\_resource\_id)

Description: The resource ID of the reverse peering resource.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
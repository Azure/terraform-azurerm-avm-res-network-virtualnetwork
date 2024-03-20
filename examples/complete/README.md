<!-- BEGIN_TF_DOCS -->
# Azure Verified Module for Azure Virtual Networks

This sample shows how to create and manage Azure Virtual Networks (vNets) and their associated resources with all options enabled.

```hcl
#Importing the Azure naming module to ensure resources have unique CAF compliant names.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

#Generating a random ID to be used for creating unique resource names.
resource "random_id" "rg_name" {
  byte_length = 8
}

#Creating a resource group with a unique name in the specified location.
resource "azurerm_resource_group" "example" {
  location = var.rg_location
  name     = module.naming.resource_group.name_unique
}

#Creating a Network Security Group with a unique name in the specified location.
resource "azurerm_network_security_group" "nsg1" {
  location            = var.vnet_location
  name                = "test-${random_id.rg_name.hex}-nsg"
  resource_group_name = azurerm_resource_group.example.name
}

#Creating a Route Table with a unique name in the specified location.
resource "azurerm_route_table" "rt1" {
  location            = var.vnet_location
  name                = "test-${random_id.rg_name.hex}-rt"
  resource_group_name = azurerm_resource_group.example.name
}

#Creating a DDoS Protection Plan in the specified location.
resource "azurerm_network_ddos_protection_plan" "example" {
  location            = var.vnet_location
  name                = "example-protection-plan"
  resource_group_name = azurerm_resource_group.example.name
}

#Creating a NAT Gateway in the specified location.
resource "azurerm_nat_gateway" "example" {
  location            = var.vnet_location
  name                = "example-natgateway"
  resource_group_name = azurerm_resource_group.example.name
}

#Defining the first virtual network (vnet-1) with its subnets and settings.
module "vnet_1" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.example.name

  subnets = {
    subnet0 = {
      address_prefixes = ["192.168.0.0/16"]
    }
  }

  virtual_network_address_space = ["192.168.0.0/16"]
  location                      = azurerm_resource_group.example.location
  name                          = "accttest-vnet-peer"


}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.5.0)

## Resources

The following resources are used by this module:

- [azurerm_nat_gateway.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway) (resource)
- [azurerm_network_ddos_protection_plan.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_ddos_protection_plan) (resource)
- [azurerm_network_security_group.nsg1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_route_table.rt1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) (resource)
- [random_id.rg_name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_rg_location"></a> [rg\_location](#input\_rg\_location)

Description: This variable defines the Azure region where the resource group will be created.  
The default value is "westus".

Type: `string`

Default: `"westus"`

### <a name="input_vnet_location"></a> [vnet\_location](#input\_vnet\_location)

Description: This variable defines the Azure region where the virtual network will be created.  
The default value is "westus".

Type: `string`

Default: `"westus"`

## Outputs

The following outputs are exported:

### <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id)

Description: The resource ID of the virtual network.

### <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name)

Description: The name of the virtual network.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

### <a name="module_vnet_1"></a> [vnet\_1](#module\_vnet\_1)

Source: ../../

Version:

## Usage

Ensure you have Terraform installed and the Azure CLI authenticated to your Azure subscription.

Navigate to the directory containing this configuration and run:

```
terraform init
terraform plan
terraform apply
```

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

## AVM Versioning Notice

Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to https://semver.org/
<!-- END_TF_DOCS -->
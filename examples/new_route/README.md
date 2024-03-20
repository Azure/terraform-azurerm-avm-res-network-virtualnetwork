<!-- BEGIN_TF_DOCS -->
# Azure Verified Module for Azure Virtual Networks

This code sample shows how to create and manage Azure Virtual Networks (vNets) and associate route tables.

```hcl
#Importing the Azure naming module to ensure resources have unique CAF compliant names.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

resource "random_id" "rg_name" {
  byte_length = 8
}

#Creating a resource group with a unique name in the specified location.
resource "azurerm_resource_group" "example" {
  location = var.rg_location
  name     = module.naming.resource_group.name_unique
}
locals {
  subnets = {
    for i in range(3) :
    "subnet${i}" => {
      address_prefixes = [cidrsubnet(local.virtual_network_address_space, 8, i)]
      route_table = {
        id = azurerm_route_table.example.id
      }
    }
  }
  virtual_network_address_space = "10.0.0.0/16"
}

module "vnet" {
  source                        = "../../"
  resource_group_name           = azurerm_resource_group.example.name
  virtual_network_address_space = ["10.0.0.0/16"]
  subnets                       = local.subnets
  location                      = azurerm_resource_group.example.location
  name                          = "azure-subnets-vnet"

}

resource "azurerm_route_table" "example" {
  location            = azurerm_resource_group.example.location
  name                = "MyRouteTable"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_route" "example" {
  address_prefix      = local.virtual_network_address_space
  name                = "acceptanceTestRoute1"
  next_hop_type       = "VnetLocal"
  resource_group_name = azurerm_resource_group.example.name
  route_table_name    = azurerm_route_table.example.name
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

- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_route.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) (resource)
- [azurerm_route_table.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) (resource)
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

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

### <a name="module_vnet"></a> [vnet](#module\_vnet)

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
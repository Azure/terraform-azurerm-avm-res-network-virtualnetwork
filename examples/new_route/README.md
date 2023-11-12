<!-- BEGIN_TF_DOCS -->
# Azure Verified Module for Azure Virtual Networks

This code sample shows how to create and manage Azure Virtual Networks (vNets) and associate route tables.

```hcl
// Importing the Azure naming module to ensure resources have unique CAF compliant names.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

resource "random_id" "rg_name" {
  byte_length = 8
}

// Creating a resource group with a unique name in the specified location.
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
  vnet_location                 = azurerm_resource_group.example.location
  vnet_name                     = "azure-subnets-vnet"

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

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="provider_random"></a> [random](#provider\_random)

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

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information, see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

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

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the newly created vNet

### <a name="output_subnet_address_prefixes"></a> [subnet\_address\_prefixes](#output\_subnet\_address\_prefixes)

Description: The address prefixes of the newly created subnets

### <a name="output_subnet_names"></a> [subnet\_names](#output\_subnet\_names)

Description: The names of the newly created subnets

### <a name="output_vnet_address_space"></a> [vnet\_address\_space](#output\_vnet\_address\_space)

Description: The address space of the newly created vNet

### <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id)

Description: The id of the newly created vNet

### <a name="output_vnet_location"></a> [vnet\_location](#output\_vnet\_location)

Description: The location of the newly created vNet

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
<!-- END_TF_DOCS -->
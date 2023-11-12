<!-- BEGIN_TF_DOCS -->
# Azure Verified Module for Azure Virtual Networks

This code sample shows how to create and manage Azure Virtual Networks (vNets) and associate a DDOS Protection Plan.

```hcl
resource "random_id" "rg_name" {
  byte_length = 8
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# Creating a resource group with a unique name in the specified location.
resource "azurerm_resource_group" "example" {
  location = var.rg_location
  name     = module.naming.resource_group.name_unique
}

locals {
  subnets = {
    for i in range(3) : "subnet${i}" => {
      address_prefixes = [cidrsubnet(local.virtual_network_address_space, 8, i)]
    }
  }
  virtual_network_address_space = "10.0.0.0/16"
}

module "vnet" {
  source                        = "../../"
  resource_group_name           = azurerm_resource_group.example.name
  subnets                       = local.subnets
  virtual_network_address_space = [local.virtual_network_address_space]
  vnet_location                 = var.vnet_location
  vnet_name                     = "azure-subnets-vnet"
  new_network_ddos_protection_plan = {
    name = "ddos-protection-for-asv"
  }
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

Default: `"eastus"`

### <a name="input_vnet_location"></a> [vnet\_location](#input\_vnet\_location)

Description: n/a

Type: `string`

Default: `"eastus"`

## Outputs

The following outputs are exported:

### <a name="output_test_vnet_id"></a> [test\_vnet\_id](#output\_test\_vnet\_id)

Description: n/a

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
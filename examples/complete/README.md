<!-- BEGIN_TF_DOCS -->
# Azure Verified Module for Azure Virtual Networks

This sample shows how to create and manage Azure Virtual Networks (vNets) and their associated resources with all options enabled.

```hcl
// Importing the Azure naming module to ensure resources have unique CAF compliant names.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

// Creating a resource group with a unique name in the specified location.
resource "azurerm_resource_group" "example" {
  location = var.rg_location
  name     = module.naming.resource_group.name_unique
}

// Creating a Network Security Group with a unique name in the specified resource group and location.
resource "azurerm_network_security_group" "nsg1" {
  location            = var.vnet_location
  name                = module.naming.network_security_group.name
  resource_group_name = azurerm_resource_group.example.name
}

// Creating a Route Table with a unique name in the specified resource group and location.
resource "azurerm_route_table" "rt1" {
  location            = var.vnet_location
  name                = module.naming.route_table.name
  resource_group_name = azurerm_resource_group.example.name
}

// Creating a virtual network with specified configurations, subnets, delegations, and network policies.
module "vnet" {
  source              = "../../"
  name                = module.naming.virtual_network.name
  enable_telemetry    = true
  resource_group_name = azurerm_resource_group.example.name
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names        = ["subnet1", "subnet2", "subnet3"]
  vnet_location       = var.vnet_location

  // Associating Network Security Group to subnet1.
  nsg_ids = {
    subnet1 = azurerm_network_security_group.nsg1.id
  }

  // Enabling specific service endpoints on subnet1 and subnet2.
  subnet_service_endpoints = {
    subnet1 = ["Microsoft.Storage"]
    subnet2 = ["Microsoft.Sql", "Microsoft.AzureActiveDirectory"]
  }

  // Configuring service delegation for subnet1 and subnet2.
  subnet_delegation = {
    subnet1 = [
      {
        name = "Microsoft.Web/serverFarms"
        service_delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    ]
    subnet2 = [
      {
        name = "Microsoft.Sql/managedInstances"
        service_delegation = {
          name    = "Microsoft.Sql/managedInstances"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    ]
  }

  // Associating Route Table to subnet1.
  route_tables_ids = {
    subnet1 = azurerm_route_table.rt1.id
  }

  // Applying tags to the virtual network.
  tags = {
    environment = "dev"
    costcenter  = "it"
  }

  // Enabling private link endpoint network policies on subnet2 and subnet3.
  private_link_endpoint_network_policies_enabled = {
    subnet2 = true
  }
  private_link_service_network_policies_enabled = {
    subnet3 = true
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

## Resources

The following resources are used by this module:

- [azurerm_network_security_group.nsg1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_route_table.rt1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) (resource)

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
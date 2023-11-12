<!-- BEGIN_TF_DOCS -->
# Azure Verified Module for Azure Virtual Networks

This sample shows how to create and manage Azure Virtual Networks (vNets) and their associated resources with all options enabled.

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

resource "azurerm_network_security_group" "nsg1" {
  location            = var.vnet_location
  name                = "test-${random_id.rg_name.hex}-nsg"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_route_table" "rt1" {
  location            = var.vnet_location
  name                = "test-${random_id.rg_name.hex}-rt"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_network_ddos_protection_plan" "example" {
  location            = var.vnet_location
  name                = "example-protection-plan"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_nat_gateway" "example" {
  location            = var.vnet_location
  name                = "example-natgateway"
  resource_group_name = azurerm_resource_group.example.name
}

module "vnet-1" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.example.name

  subnets = {
    subnet0 = {
      address_prefixes = ["192.168.0.0/16"]

    }
  }

  virtual_network_address_space = ["192.168.0.0/16"]
  vnet_location                 = azurerm_resource_group.example.location
  vnet_name                     = "accttest-vnet-peer"

}

module "vnet-2" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.example.name

  subnets = {
    subnet0 = {
      address_prefixes                          = ["10.0.0.0/24"]
      private_endpoint_network_policies_enabled = false
      service_endpoints = [
        "Microsoft.Storage", "Microsoft.Sql"
      ]
      delegations = [
        {
          name = "Microsoft.Sql.managedInstances"
          service_delegation = {
            name = "Microsoft.Sql/managedInstances"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action",
              "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
              "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
            ]
          }
        }
      ]
    }
    subnet1 = {
      address_prefixes                          = ["10.0.1.0/24"]
      private_endpoint_network_policies_enabled = false
      service_endpoints                         = ["Microsoft.AzureActiveDirectory"]
    }
    subnet2 = {
      address_prefixes = ["10.0.2.0/24"]
      nat_gateway = {
        id = azurerm_nat_gateway.example.id
      }
      network_security_group = {
        id = azurerm_network_security_group.nsg1.id
      }
      route_table = {
        id = azurerm_route_table.rt1.id
      }
    }
  }
  virtual_network_dns_servers = {
    dns_servers = ["8.8.8.8"]
  }
  virtual_network_ddos_protection_plan = {
    id     = azurerm_network_ddos_protection_plan.example.id
    enable = true
  }
  //creates a 1 way vnet peering from vnet-2 to vnet-1
  vnet_peering_config = {
    peering1 = {
      remote_vnet_id          = module.vnet-1.vnet_id
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    }
  }

  virtual_network_address_space = ["10.0.0.0/16"]
  vnet_location                 = azurerm_resource_group.example.location
  vnet_name                     = "accttest-vnet"
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

### <a name="module_vnet-1"></a> [vnet-1](#module\_vnet-1)

Source: ../../

Version:

### <a name="module_vnet-2"></a> [vnet-2](#module\_vnet-2)

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
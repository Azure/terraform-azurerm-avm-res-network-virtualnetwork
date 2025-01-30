<!-- BEGIN_TF_DOCS -->
# Peer only specified address spaces example for Azure Virtual Network module

This sample shows how to create peerings only for specific address spaces in a virtual network.

```hcl
terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "~> 0.3"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

#Defining the first virtual network (vnet-1) with its subnets and settings.
module "vnet1" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_network.name_unique}-1"

  address_space = ["10.4.0.0/16", "10.5.0.0/16"]

  subnets = {
    subnet1 = {
      name             = "${module.naming.subnet.name_unique}-1-1"
      address_prefixes = ["10.4.1.0/24", "10.4.2.0/24"]
    }
    subnet2 = {
      name             = "${module.naming.subnet.name_unique}-1-2"
      address_prefixes = ["10.4.3.0/24", "10.4.4.0/24"]
    }
    subnet3 = {
      name             = "${module.naming.subnet.name_unique}-1-3"
      address_prefixes = ["10.5.5.0/24", "10.5.6.0/24"]
    }
  }
}

module "vnet2" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_network.name_unique}-2"
  address_space       = ["10.6.0.0/16", "10.7.0.0/16"]

  subnets = {
    subnet1 = {
      name             = "${module.naming.subnet.name_unique}-2-1"
      address_prefixes = ["10.6.1.0/24", "10.6.2.0/24"]
    }
    subnet2 = {
      name             = "${module.naming.subnet.name_unique}-2-2"
      address_prefixes = ["10.6.3.0/24", "10.6.4.0/24"]
    }
    subnet3 = {
      name             = "${module.naming.subnet.name_unique}-2-3"
      address_prefixes = ["10.7.5.0/24", "10.7.6.0/24"]
    }
  }

  peerings = {
    peertovnet1 = {
      name                               = "${module.naming.virtual_network_peering.name_unique}-vnet2-to-vnet1"
      remote_virtual_network_resource_id = module.vnet1.resource_id
      allow_forwarded_traffic            = true
      allow_gateway_transit              = true
      allow_virtual_network_access       = true
      peer_complete_vnets                = false
      local_peered_address_spaces = [
        {
          address_prefix = "10.6.1.0/24"
        },
        {
          address_prefix = "10.6.2.0/24"
        }
      ]
      remote_peered_address_spaces = [
        {
          address_prefix = "10.4.1.0/24"
        },
        {
          address_prefix = "10.4.2.0/24"
        }
      ]

      create_reverse_peering               = true
      reverse_name                         = "${module.naming.virtual_network_peering.name_unique}-vnet1-to-vnet2"
      reverse_allow_forwarded_traffic      = false
      reverse_allow_gateway_transit        = false
      reverse_allow_virtual_network_access = true
      reverse_peer_complete_vnets          = false
      reverse_local_peered_address_spaces = [
        {
          address_prefix = "10.4.1.0/24"
        },
        {
          address_prefix = "10.4.2.0/24"
        }
      ]
      reverse_remote_peered_address_spaces = [
        {
          address_prefix = "10.6.1.0/24"
        },
        {
          address_prefix = "10.6.2.0/24"
        }
      ]
    }
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.74)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_name"></a> [name](#output\_name)

Description: The resource name of the virtual network.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The virtual network resource.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The resource ID of the virtual network.

### <a name="output_subnet1"></a> [subnet1](#output\_subnet1)

Description: The subnet resource.

### <a name="output_subnets"></a> [subnets](#output\_subnets)

Description: Information about the subnets created in the module.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: ~> 0.3

### <a name="module_vnet1"></a> [vnet1](#module\_vnet1)

Source: ../../

Version:

### <a name="module_vnet2"></a> [vnet2](#module\_vnet2)

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
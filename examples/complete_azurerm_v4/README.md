<!-- BEGIN_TF_DOCS -->
# Complete example for Azure Virtual Network module using azurerm v4 and azapi v2

This sample shows how to create and manage Azure Virtual Networks (vNets) and their associated resources with all options enabled.

```hcl
terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.7"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
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

#Creating a Route Table with a unique name in the specified location.
resource "azurerm_route_table" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.route_table.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

# Creating a DDoS Protection Plan in the specified location.
resource "azurerm_network_ddos_protection_plan" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.network_ddos_protection_plan.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

#Creating a NAT Gateway in the specified location.
resource "azurerm_nat_gateway" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.nat_gateway.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

# Fetching the public IP address of the Terraform executor used for NSG
data "http" "public_ip" {
  method = "GET"
  url    = "http://api.ipify.org?format=json"
}

resource "azurerm_network_security_group" "https" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.network_security_group.name_unique
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "443"
    direction                  = "Inbound"
    name                       = "AllowInboundHTTPS"
    priority                   = 100
    protocol                   = "Tcp"
    source_address_prefix      = jsondecode(data.http.public_ip.response_body).ip
    source_port_range          = "*"
  }
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_storage_account" "this" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.this.location
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.this.name
}

resource "azurerm_subnet_service_endpoint_storage_policy" "this" {
  location            = azurerm_resource_group.this.location
  name                = "sep-${module.naming.unique-seed}"
  resource_group_name = azurerm_resource_group.this.name

  definition {
    name = "name1"
    service_resources = [
      azurerm_resource_group.this.id,
      azurerm_storage_account.this.id
    ]
    description = "definition1"
    service     = "Microsoft.Storage"
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

#Defining the first virtual network (vnet-1) with its subnets and settings.
module "vnet1" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique

  address_space = ["192.168.0.0/16"]

  dns_servers = {
    dns_servers = ["8.8.8.8"]
  }

  ddos_protection_plan = {
    id = azurerm_network_ddos_protection_plan.this.id
    # due to resource cost
    enable = false
  }

  role_assignments = {
    role1 = {
      principal_id               = azurerm_user_assigned_identity.this.principal_id
      role_definition_id_or_name = "Contributor"
    }
  }

  enable_vm_protection = true

  encryption = {
    enabled = true
    #enforcement = "DropUnencrypted"  # NOTE: This preview feature requires approval, leaving off in example: Microsoft.Network/AllowDropUnecryptedVnet
    enforcement = "AllowUnencrypted"
  }

  flow_timeout_in_minutes = 30

  subnets = {
    subnet0 = {
      name                            = "${module.naming.subnet.name_unique}0"
      default_outbound_access_enabled = false
      #sharing_scope                   = "Tenant"  #NOTE: This preview feature requires approval, leaving off in example: Microsoft.Network/EnableSharedVNet
      address_prefixes = ["192.168.0.0/24", "192.168.2.0/24"]
    }
    subnet1 = {
      name                            = "${module.naming.subnet.name_unique}1"
      address_prefixes                = ["192.168.1.0/24"]
      default_outbound_access_enabled = false
      delegation = [{
        name = "Microsoft.Web.serverFarms"
        service_delegation = {
          name = "Microsoft.Web/serverFarms"
        }
      }]
      nat_gateway = {
        id = azurerm_nat_gateway.this.id
      }
      network_security_group = {
        id = azurerm_network_security_group.https.id
      }
      route_table = {
        id = azurerm_route_table.this.id
      }
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      service_endpoint_policies = {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      }
      role_assignments = {
        role1 = {
          principal_id               = azurerm_user_assigned_identity.this.principal_id
          role_definition_id_or_name = "Contributor"
        }
      }
    }
  }

  diagnostic_settings = {
    sendToLogAnalytics = {
      name                           = "sendToLogAnalytics"
      workspace_resource_id          = azurerm_log_analytics_workspace.this.id
      log_analytics_destination_type = "Dedicated"
    }
  }
}

module "vnet2" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_network.name_unique}2"
  address_space       = ["10.0.0.0/27"]

  encryption = {
    enabled     = true
    enforcement = "AllowUnencrypted"
  }

  peerings = {
    peertovnet1 = {
      name                                  = "${module.naming.virtual_network_peering.name_unique}-vnet2-to-vnet1"
      remote_virtual_network_resource_id    = module.vnet1.resource_id
      allow_forwarded_traffic               = true
      allow_gateway_transit                 = true
      allow_virtual_network_access          = true
      do_not_verify_remote_gateways         = false
      enable_only_ipv6_peering              = false
      use_remote_gateways                   = false
      create_reverse_peering                = true
      reverse_name                          = "${module.naming.virtual_network_peering.name_unique}-vnet1-to-vnet2"
      reverse_allow_forwarded_traffic       = false
      reverse_allow_gateway_transit         = false
      reverse_allow_virtual_network_access  = true
      reverse_do_not_verify_remote_gateways = false
      reverse_enable_only_ipv6_peering      = false
      reverse_use_remote_gateways           = false
    }
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.7)

- <a name="requirement_http"></a> [http](#requirement\_http) (~> 3.4)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway) (resource)
- [azurerm_network_ddos_protection_plan.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_ddos_protection_plan) (resource)
- [azurerm_network_security_group.https](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_route_table.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) (resource)
- [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_subnet_service_endpoint_storage_policy.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_service_endpoint_storage_policy) (resource)
- [azurerm_user_assigned_identity.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [http_http.public_ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) (data source)

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
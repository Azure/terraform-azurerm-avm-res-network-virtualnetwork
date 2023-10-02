<!-- BEGIN_TF_DOCS -->
# Azure Verified Module for Azure Virtual Networks

This code sample shows how to create and manage Azure Virtual Networks (vNets) and associate Netwrok Security Groups.

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

// Creating a virtual network with specified configurations, subnets, and associated Network Security Groups.
module "vnet" {
  source              = "../../"
  name                = module.naming.virtual_network.name
  enable_telemetry    = var.enable_telemetry
  resource_group_name = azurerm_resource_group.example.name
  vnet_location       = var.vnet_location
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names        = ["subnet1", "subnet2", "subnet3"]

  // Associating the same Network Security Group to all subnets.
  nsg_ids = {
    subnet1 = azurerm_network_security_group.ssh.id
    subnet2 = azurerm_network_security_group.ssh.id
    subnet3 = azurerm_network_security_group.ssh.id
  }

  // Applying tags to the virtual network.
  tags = {
    environment = "dev"
    costcenter  = "it"
  }
}

// Fetching the public IP address of the Terraform executor.
data "curl" "public_ip" {
  http_method = "GET"
  uri         = "https://api.ipify.org?format=json"
}

// Creating a Network Security Group with a rule allowing SSH access from the executor's IP address.
resource "azurerm_network_security_group" "ssh" {
  location            = azurerm_resource_group.example.location
  name                = module.naming.network_security_group.name
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    direction                  = "Inbound"
    name                       = "test123"
    priority                   = 100
    protocol                   = "Tcp"
    source_address_prefix      = jsondecode(data.curl.public_ip.response).ip
    source_port_range          = "*"
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>=1.2)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>=3.11.0, <4.0)

- <a name="requirement_curl"></a> [curl](#requirement\_curl) (1.0.2)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>=3.11.0, <4.0)

- <a name="provider_curl"></a> [curl](#provider\_curl) (1.0.2)

## Resources

The following resources are used by this module:

- [azurerm_network_security_group.ssh](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [curl_curl.public_ip](https://registry.terraform.io/providers/anschoewe/curl/1.0.2/docs/data-sources/curl) (data source)

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
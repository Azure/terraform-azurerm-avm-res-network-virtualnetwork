# Azure Verified Module for Azure Virtual Networks

This module provides a generic way to create and manage Azure Virtual Networks (vNets) and their associated resources.

To use this module in your Terraform configuration, you'll need to provide values for the required variables. Here's a basic example:

```terraform
module "azure_vnet" {
  source = "./path_to_this_module"

  address_spaces      = ["10.0.0.0/16"]
  vnet_location       = "East US"
  name                = "myVNet"
  resource_group_name = "myResourceGroup"
  // ... other required variables ...
}
```

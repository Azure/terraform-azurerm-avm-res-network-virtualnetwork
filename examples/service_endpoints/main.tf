terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azapi" {}

## Section to provide a random suffix for the resource names
# This allows us to randomize the names of the resources
resource "random_string" "this" {
  length  = 6
  numeric = true
  special = false
  upper   = false
}


## Section to create a resource group for the virtual network
# This creates a resource group in the specified location
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  location = local.selected_region.name
  name     = "rg-avm-vnet-service-endpoints-${random_string.this.result}"
}

# This is the module call
# Do not specify location here as the PIN data will be used to determine the deployment region
module "virtualnetwork" {
  source = "../../"

  location      = module.resource_group.location
  parent_id     = module.resource_group.resource_id
  address_space = ["10.0.0.0/16"]
  name          = "vnet-avm-service-endpoints-${random_string.this.result}"
  subnets = {
    # Subnet with service endpoints
    subnet_all_endpoints = {
      name           = "subnet-all-regions"
      address_prefix = "10.0.0.0/24"
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.Sql",
        "Microsoft.AzureCosmosDB",
        "Microsoft.KeyVault",
        "Microsoft.ServiceBus",
        "Microsoft.EventHub",
        "Microsoft.Web",
        "Microsoft.CognitiveServices",
        # Container registry is in preview and not available in all regions
        # "Microsoft.ContainerRegistry",
      ]
    }
    subnet_storage_global = {
      name              = "subnet-storage-global"
      address_prefix    = "10.0.1.0/24"
      service_endpoints = ["Microsoft.Storage.Global"]
    }
  }
}

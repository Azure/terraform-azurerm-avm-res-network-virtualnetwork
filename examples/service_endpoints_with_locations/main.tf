terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
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
resource "azurerm_resource_group" "this" {
  location = local.selected_region
  name     = "rg-avm-vnet-service-endpoints-${random_string.this.result}"
}

# This is the module call
# Do not specify location here as the PIN data will be used to determine the deployment region
module "virtualnetwork" {
  source = "../../"

  location      = azurerm_resource_group.this.location
  parent_id     = azurerm_resource_group.this.id
  address_space = ["10.0.0.0/16"]
  name          = "vnet-avm-service-endpoints-${random_string.this.result}"
  subnets = {
    # Subnet with service endpoints for all regions
    subnet_all_endpoints = {
      name           = "subnet-all-regions"
      address_prefix = "10.0.0.0/24"
      # New format: allow all regions with "*"
      service_endpoints_with_location = [
        {
          service   = "Microsoft.Storage"
          locations = [local.region.name, local.region.paired_region_name]
        },
        {
          service   = "Microsoft.Sql"
          locations = [local.region.name]
        },
        {
          service   = "Microsoft.AzureCosmosDB"
          locations = ["*"]
        },
        {
          service   = "Microsoft.KeyVault"
          locations = ["*"]
        },
        {
          service   = "Microsoft.ServiceBus"
          locations = ["*"]
        },
        {
          service   = "Microsoft.EventHub"
          locations = ["*"]
        },
        {
          service   = "Microsoft.Web"
          locations = ["*"]
        },
        {
          service   = "Microsoft.CognitiveServices"
          locations = ["*"]
        }
        # Container registry is in preview and not available in all regions
        # {
        #   service   = "Microsoft.ContainerRegistry"
        #   locations = ["*"]
        # },
      ]
    }
    subnet_storage_global = {
      name           = "subnet-storage-global"
      address_prefix = "10.0.1.0/24"
      service_endpoints_with_location = [
        {
          service   = "Microsoft.Storage.Global"
          locations = ["*"]
        },
      ]
    }
  }
}

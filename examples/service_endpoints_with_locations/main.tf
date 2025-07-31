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

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "~> 0.8"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
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
  location = module.regions.regions[random_integer.region_index.result].name
  name     = "rg-avm-vnet-service-endpoints-${random_string.this.result}"
}

# This is the module call
# Do not specify location here as the PIN data will be used to determine the deployment region
module "virtualnetwork" {
  source = "../../"

  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  name                = "vnet-avm-service-endpoints-${random_string.this.result}"
  subnets = {
    # Subnet with legacy string format (backward compatibility)
    subnet_legacy = {
      name           = "subnet-legacy"
      address_prefix = "10.0.1.0/24"
      # Legacy format: simple string list
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }

    # Subnet with new object format and specific regions
    subnet_with_locations = {
      name           = "subnet-with-locations"
      address_prefix = "10.0.2.0/24"
      # New format: objects with location restrictions
      service_endpoints_with_location = [
        {
          service   = "Microsoft.Storage"
          locations = ["uksouth", "ukwest"] # Restrict to UK regions
        },
        {
          service   = "Microsoft.KeyVault"
          locations = ["westeurope", "northeurope"] # Restrict to Western Europe regions
        }
      ]
    }

    # Subnet with service endpoints for all regions
    subnet_all_regions = {
      name           = "subnet-all-regions"
      address_prefix = "10.0.3.0/24"
      # New format: allow all regions with "*"
      service_endpoints_with_location = [
        {
          service   = "Microsoft.Storage"
          locations = ["*"] # All regions
        },
        {
          service   = "Microsoft.Sql"
          locations = ["*"] # All regions
        }
      ]
    }

    # Subnet with mixed format - some with locations, some without
    subnet_mixed = {
      name           = "subnet-mixed"
      address_prefix = "10.0.4.0/24"
      # New format: mix of with and without locations
      service_endpoints_with_location = [
        {
          service = "Microsoft.Storage"
          # No locations specified - defaults to current region
        },
        {
          service   = "Microsoft.ContainerRegistry"
          locations = ["eastus", "westus2"] # Specific US regions
        }
      ]
    }
  }
  tags = {
    environment = "dev"
    example     = "service-endpoints-with-locations"
  }
}

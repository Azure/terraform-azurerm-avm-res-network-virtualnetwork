terraform {
  required_version = ">= 1.9.2"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.13.1, < 3.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71.0, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0, < 4.0.0"
    }
  }
}

provider "azapi" {}
provider "azurerm" {
  features {}
}
provider "random" {}

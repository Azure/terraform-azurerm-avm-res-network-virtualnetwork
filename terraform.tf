terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

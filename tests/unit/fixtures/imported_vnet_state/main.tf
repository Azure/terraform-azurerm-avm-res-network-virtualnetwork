terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}

resource "azapi_resource" "vnet" {
  location  = "westeurope"
  name      = "vnet-unit-test"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
      }
      subnets = [
        {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/vnet-unit-test/subnets/existing"
        }
      ]
      virtualNetworkPeerings = [
        {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/vnet-unit-test/virtualNetworkPeerings/RemoteVnetToHubPeering_test"
        }
      ]
    }
  }

  response_export_values = []
}

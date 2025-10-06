# Get current subscription context
data "azurerm_subscription" "current" {}

# Get a random integer for resource naming
resource "random_integer" "this" {
  max = 9999
  min = 1000
}

# Create resource group
resource "azurerm_resource_group" "this" {
  location = "East US"
  name     = "rg-vnet-encryption-${random_integer.this.result}"
}

# STEP 1: Register Azure subscription feature for VNet encryption with DropUnencrypted enforcement
# This is a prerequisite that must be done once per subscription before creating encrypted VNets
resource "azapi_update_resource" "allow_drop_unencrypted_vnet" {
  resource_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowDropUnecryptedVnet"
  type        = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
}

# STEP 2: Create VNet with encryption enabled (depends on the feature registration)
module "vnet_with_encryption" {
  source = "../.."

  location      = azurerm_resource_group.this.location
  parent_id     = azurerm_resource_group.this.id
  address_space = ["10.0.0.0/16"]
  # Encryption configuration - this requires the feature registration above
  encryption = {
    enabled     = true
    enforcement = "DropUnencrypted" # This requires the AllowDropUnecryptedVnet feature
  }
  # Basic VNet configuration
  name = "vnet-encrypted-${random_integer.this.result}"
  # Example subnets
  subnets = {
    subnet1 = {
      name           = "encrypted-subnet-1"
      address_prefix = "10.0.1.0/24"
    }
    subnet2 = {
      name           = "encrypted-subnet-2"
      address_prefix = "10.0.2.0/24"
    }
  }

  # Ensure the feature is registered before creating the VNet
  depends_on = [azapi_update_resource.allow_drop_unencrypted_vnet]
}

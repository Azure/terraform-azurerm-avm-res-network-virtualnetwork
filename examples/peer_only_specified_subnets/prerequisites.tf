# This file contains prerequisite resources that must be registered before deploying the main example.
# These feature registrations are required at the subscription level.

# Register the feature to allow multiple peering links between VNets
# This is required for subnet-level peering scenarios
resource "azapi_update_resource" "allow_multiple_peering_links_between_vnets" {
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowMultiplePeeringLinksBetweenVnets"
  type        = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
}

data "azurerm_client_config" "current" {}

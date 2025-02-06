resource "azapi_resource" "vnet" {
  type = "Microsoft.Network/virtualNetworks@2023-11-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = var.address_space
      }
      bgpCommunities = var.bgp_community != null ? {
        virtualNetworkCommunity = var.bgp_community
      } : null
      dhcpOptions = var.dns_servers != null ? {
        dnsServers = var.dns_servers.dns_servers
      } : null
      ddosProtectionPlan = var.ddos_protection_plan != null ? {
        id = var.ddos_protection_plan.id
      } : null
      enableDdosProtection = var.ddos_protection_plan != null ? var.ddos_protection_plan.enable : false
      enableVmProtection   = var.enable_vm_protection
      encryption = var.encryption != null ? {
        enabled     = var.encryption.enabled
        enforcement = var.encryption.enforcement
      } : null
      flowTimeoutInMinutes = var.flow_timeout_in_minutes
    }
    extendedLocation = var.extended_location != null ? {
      name = var.extended_location.name
      type = var.extended_location.type
    } : null
  }
  location                  = var.location
  name                      = var.name
  parent_id                 = "/subscriptions/${local.subscription_id}/resourceGroups/${var.resource_group_name}"
  schema_validation_enabled = true
  tags                      = var.tags

  depends_on = [azapi_update_resource.allow_drop_unencrypted_vnet]

  lifecycle {
    ignore_changes = [
      body.properties.subnets,
    ]
  }
}

resource "azapi_update_resource" "allow_drop_unencrypted_vnet" {
  count = var.encryption != null ? (var.encryption.enforcement == "DropUnencrypted" ? 1 : 0) : 0

  type = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
  resource_id = "/subscriptions/${local.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowDropUnecryptedVnet"
}

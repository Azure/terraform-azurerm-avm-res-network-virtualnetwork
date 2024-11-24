locals {
  # Define which addressSpace values to use based on the presence of the IPAM variable.
  # If the IPAM pool is not provided, use the addressPrefixes.
  # If the IPAM pool is provided, use the ipamPoolPrefixAllocations, exclude the addressPrefixes so TF doesn't 
  # generate a diff when it is set after calling IPAM.
  address_options = {
    addressPrefixes = {
      addressPrefixes = var.address_space
    }
    ipamPoolPrefixAllocations = {
      ipamPoolPrefixAllocations = [
        {
          numberOfIpAddresses = tostring(try(var.ipam_pool.number_of_addresses, 0))
          pool = {
            id = try(var.ipam_pool.id, "")
          }
        }
      ]
    }
  }
}

resource "azapi_resource" "vnet" {
  type = "Microsoft.Network/virtualNetworks@2024-03-01"
  body = {
    properties = {
      addressSpace = local.address_options[can(var.ipam_pool.id) ? "ipamPoolPrefixAllocations" : "addressPrefixes"]
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
  schema_validation_enabled = !can(var.ipam_pool.id)
  tags                      = var.tags

  depends_on = [azapi_update_resource.allow_drop_unencrypted_vnet]
}

resource "azapi_update_resource" "allow_drop_unencrypted_vnet" {
  count = var.encryption != null ? (var.encryption.enforcement == "DropUnencrypted" ? 1 : 0) : 0

  type = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
  resource_id = "/subscriptions/${local.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowDropUnecryptedVnet"
}

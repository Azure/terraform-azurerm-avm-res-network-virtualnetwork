locals {
  # When IPAM is used, after the prefix has been allocated, it is populated to addressPrefixes.
  # The next time TF is planned it will try to assert addressPrefixes back to null
  # ignore_changes is not dynamic and cannot be used to ignore changes to the addressPrefixes property based on the presence of IPAM.
  # To avoid this, we need to check if the IPAM pool is requested and define which values to use based on the presence of the IPAM variable.
  # If the IPAM pool is not provided, use the addressPrefixes.
  # If the IPAM pool is provided, use the ipamPoolPrefixAllocations
  address_options = {
    addressPrefixes = {
      addressPrefixes = var.address_space
    }
    ipamPoolPrefixAllocations = {
      ipamPoolPrefixAllocations = var.ipam_pools != null ? [
        for ipam_pool in var.ipam_pools : {
          numberOfIpAddresses = tostring(pow(2, (ipam_pool.prefix_length >= 48 ? 128 : 32) - ipam_pool.prefix_length))
          pool = {
            id = ipam_pool.id
          }
      }] : []
    }
  }
}

resource "azapi_resource" "vnet" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${local.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  body = {
    properties = {
      addressSpace = local.address_options[var.ipam_pools != null ? "ipamPoolPrefixAllocations" : "addressPrefixes"]
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
  retry                     = var.retry
  schema_validation_enabled = true
  tags                      = var.tags

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }

  depends_on = [azapi_update_resource.allow_drop_unencrypted_vnet]

  lifecycle {
    ignore_changes = [
      body.properties.subnets,
      body.properties.virtualNetworkPeerings
    ]
  }
}

resource "azapi_update_resource" "allow_drop_unencrypted_vnet" {
  count = var.encryption != null ? (var.encryption.enforcement == "DropUnencrypted" ? 1 : 0) : 0

  resource_id = "/subscriptions/${local.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowDropUnecryptedVnet"
  type        = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
}

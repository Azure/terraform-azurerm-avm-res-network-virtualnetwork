# Keep API-returned child collections in the parent PUT without masking changes
# to the rest of the VNet body; lifecycle ignores on dynamic body mask all of it.
data "azapi_resource" "existing_vnet" {
  name             = var.name
  parent_id        = var.parent_id
  type             = "Microsoft.Network/virtualNetworks@2024-07-01"
  ignore_not_found = true
  response_export_values = [
    "properties.subnets",
    "properties.virtualNetworkPeerings",
  ]
}

resource "azapi_resource" "vnet" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  body = {
    properties = merge({
      addressSpace = merge(
        var.ipam_pools != null ? {
          ipamPoolPrefixAllocations = [
            for ipam_pool in var.ipam_pools : {
              numberOfIpAddresses = ipam_pool.number_of_ip_addresses != null ? ipam_pool.number_of_ip_addresses : tostring(pow(2, (ipam_pool.prefix_length >= 48 ? 128 : 32) - ipam_pool.prefix_length))
              pool = {
                id = ipam_pool.id
              }
            }
          ]
        } : {},
        var.ipam_pools == null ? {
          addressPrefixes = var.address_space != null ? var.address_space : []
        } : {}
      )
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
      }, data.azapi_resource.existing_vnet.exists ? {
      for collection in ["subnets", "virtualNetworkPeerings"] :
      collection => data.azapi_resource.existing_vnet.output.properties[collection]
      if try(data.azapi_resource.existing_vnet.output.properties[collection] != null, false)
    } : {})
    extendedLocation = var.extended_location != null ? {
      name = var.extended_location.name
      type = var.extended_location.type
    } : null
  }
  # ignore_body_changes is a write-only argument; collapse an empty list to null
  # so the argument is absent (and the module stays usable on Terraform < 1.11)
  # when the feature is unused.
  ignore_body_changes = length(var.ignore_body_changes.virtual_networks) > 0 ? var.ignore_body_changes.virtual_networks : null
  # Export specific properties needed for IPAM VNets based on actual API response structure
  response_export_values = var.ipam_pools != null ? [
    "properties.addressSpace.addressPrefixes"
  ] : []
  retry = var.retry
  tags  = var.tags

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }
}



resource "azapi_resource" "vnet" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  body = {
    properties = {
      addressSpace = merge(
        var.ipam_pools != null ? {
          ipamPoolPrefixAllocations = [
            for ipam_pool in var.ipam_pools : {
              numberOfIpAddresses = tostring(pow(2, (ipam_pool.prefix_length >= 48 ? 128 : 32) - ipam_pool.prefix_length))
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
    }
    extendedLocation = var.extended_location != null ? {
      name = var.extended_location.name
      type = var.extended_location.type
    } : null
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  # Export specific properties needed for IPAM VNets based on actual API response structure
  response_export_values = var.ipam_pools != null ? [
    "properties.addressSpace.addressPrefixes"
  ] : []
  retry          = var.retry
  tags           = var.tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }
}



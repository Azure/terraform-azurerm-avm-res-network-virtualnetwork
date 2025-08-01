resource "azapi_resource" "vnet" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${local.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.Network/virtualNetworks@2023-11-01"
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
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  # We do not use outputs, so disabling them
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }

  depends_on = [azapi_update_resource.allow_drop_unencrypted_vnet]
}

resource "azapi_update_resource" "allow_drop_unencrypted_vnet" {
  count = var.encryption != null ? (var.encryption.enforcement == "DropUnencrypted" ? 1 : 0) : 0

  resource_id = "/subscriptions/${local.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/AllowDropUnecryptedVnet"
  type        = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

resource "azapi_resource" "vnet" {
  type = "Microsoft.Network/virtualNetworks@2023-11-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = var.address_space
      }
      dhcpOptions = var.dns_servers != null ? {
        dnsServers = var.dns_servers.dns_servers
      } : null
      ddosProtectionPlan = var.ddos_protection_plan != null ? {
        id = var.ddos_protection_plan.id
      } : null
      enableDdosProtection = var.ddos_protection_plan != null ? var.ddos_protection_plan.enable : false
    }
  }
  location                  = var.location
  name                      = var.name
  parent_id                 = "/subscriptions/${local.subscription_id}/resourceGroups/${var.resource_group_name}"
  schema_validation_enabled = true
  tags                      = var.tags
}

# azapi_resource.vnet are the virtual networks that will be created
# lifecycle ignore changes to the body to prevent subnets being deleted
# see <https://github.com/Azure/terraform-azurerm-lz-vending/issues/45> for more information 
resource "azapi_resource" "vnet" {
  count = var.use_existing_virtual_network ? 0 : 1

  type = "Microsoft.Network/virtualNetworks@2021-08-01"
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

  lifecycle {
    ignore_changes = [body, tags]

    precondition {
      condition     = var.use_existing_virtual_network ? true : (var.resource_group_name != null && var.location != null && var.name != null && var.address_space != null)
      error_message = "`var.resource_group_name`, `var.location`, `var.name` and `var.address_space` must be specified unless `var.existing_virtual_network` is supplied."
    }
  }
}

# azapi_update_resource.vnet are the virtual networks that will be created
# This is a workaround to allow updates to the virtual network without deleting the subnets created elsewhere.
# see <https://github.com/Azure/terraform-azurerm-lz-vending/issues/45> for more information 
resource "azapi_update_resource" "vnet" {
  count = var.use_existing_virtual_network ? 0 : 1

  type = "Microsoft.Network/virtualNetworks@2021-08-01"
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
    },
    tags = var.tags
  }
  resource_id = azapi_resource.vnet[0].id
}

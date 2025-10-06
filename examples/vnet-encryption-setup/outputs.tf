output "encrypted_vnet_id" {
  description = "The resource ID of the created encrypted VNet"
  value       = module.vnet_with_encryption.resource_id
}

output "encrypted_vnet_name" {
  description = "The name of the created encrypted VNet"
  value       = module.vnet_with_encryption.name
}

output "encryption_settings" {
  description = "The encryption settings applied to the VNet"
  value = {
    enabled     = true
    enforcement = "DropUnencrypted"
  }
}

output "feature_registration_id" {
  description = "The resource ID of the registered feature for VNet encryption"
  value       = azapi_update_resource.allow_drop_unencrypted_vnet.id
}

output "subscription_id" {
  description = "The subscription ID where the feature was registered"
  value       = data.azurerm_subscription.current.subscription_id
}

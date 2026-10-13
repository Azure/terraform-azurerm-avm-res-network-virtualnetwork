variable "existing_vnet_id" {
  type        = string
  description = "Azure ID of the VNet to import into the module."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks", var.existing_vnet_id))
    error_message = "The VNet ID must be a valid ARM resource ID."
  }
}

variable "location" {
  type        = string
  description = "Azure region of the VNet to import."
}

variable "parent_id" {
  type        = string
  description = "Azure resource group ID of the VNet to import."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "The parent ID must be a valid resource group ID."
  }
}

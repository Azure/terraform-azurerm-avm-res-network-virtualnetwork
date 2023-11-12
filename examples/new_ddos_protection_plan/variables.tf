variable "rg_location" {
  type        = string
  default     = "eastus"
  description = <<DESCRIPTION
This variable defines the Azure region where the resource group will be created.
The default value is "westus".
DESCRIPTION
}

variable "vnet_location" {
  type    = string
  default = "eastus"
}
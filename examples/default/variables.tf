#Specifies the location of the resource group.
variable "rg_location" {
  type        = string
  default     = "eastus"
  description = <<DESCRIPTION
This variable defines the Azure region where the resource group will be created.
The default value is "westus".
DESCRIPTION
}

#Specifies the location of the virtual network.
variable "vnet_location" {
  type        = string
  default     = "eastus"
  description = <<DESCRIPTION
This variable defines the Azure region where the virtual network will be created.
The default value is "westus".
DESCRIPTION
}

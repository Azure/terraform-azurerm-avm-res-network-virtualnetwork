#Specifies the location of the resource group.
variable "rg_location" {
  type        = string
  default     = "westus"
  description = <<DESCRIPTION
This variable defines the Azure region where the resource group will be created.
The default value is "westus".
DESCRIPTION
}

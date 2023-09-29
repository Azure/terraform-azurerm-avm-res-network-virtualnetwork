// Controls whether or not telemetry is enabled for the module.
variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information, see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

// Specifies the location of the resource group.
variable "rg_location" {
  type        = string
  default     = "westus"
  description = <<DESCRIPTION
This variable defines the Azure region where the resource group will be created.
The default value is "westus".
DESCRIPTION
}

// Specifies the location of the virtual network.
variable "vnet_location" {
  type        = string
  default     = "westus"
  description = <<DESCRIPTION
This variable defines the Azure region where the virtual network will be created.
The default value is "westus".
DESCRIPTION
}

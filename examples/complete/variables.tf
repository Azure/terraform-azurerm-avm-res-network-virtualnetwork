variable "address_space_vnet1" {
  type    = list(string)
  default = ["192.168.0.0/16"]
}

variable "address_space_vnet2" {
  type    = list(string)
  default = ["10.0.0.0/27"]
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "address_space" {
  type        = set(string)
  description = "Address prefixes for the VNet, changed between integration test runs."
}

variable "location" {
  type        = string
  description = "The Azure region for this module's resources or telemetry deployment."
  nullable    = false
}

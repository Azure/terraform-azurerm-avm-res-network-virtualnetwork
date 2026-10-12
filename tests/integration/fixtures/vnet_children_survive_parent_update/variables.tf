variable "address_space" {
  type        = set(string)
  description = "Address prefixes for the VNet, changed between integration test runs."
}

variable "address_space_vnet1" {
  type    = list(string)
  default = ["192.168.0.0/16"]
}

variable "address_space_vnet2" {
  type    = list(string)
  default = ["10.0.0.0/27"]
}

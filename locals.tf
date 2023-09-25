# TODO: insert locals here.
locals {
  subnet_names_prefixes_map = zipmap(var.subnet_names, var.subnet_prefixes)
}


locals {
  enable_telemetry = true
}

locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

locals {
  has_multiple_address_prefixes = var.multiple_address_prefixes_enabled != null ? var.multiple_address_prefixes_enabled : (var.address_prefixes != null ? length(var.address_prefixes) > 1 : false)
}

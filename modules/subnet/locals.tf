locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

locals {
  has_multiple_address_prefixes = var.address_prefixes != null ? length(var.address_prefixes) > 1 : false
}
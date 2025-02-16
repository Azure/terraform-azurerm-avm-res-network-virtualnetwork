locals {
  # make a filtered listed of role assignments that have been supplied by name, we need to do a data lookup for these
  role_assignments_by_name = {
    for key, value in var.role_assignments : key => value
    if !strcontains(lower(value.role_definition_id_or_name), lower(local.role_definition_resource_substring))
  }
  role_definition_id_map = {
    for role_key, role_assignment in var.role_assignments :
    role_key => (
      strcontains(role_assignment.role_definition_id_or_name, local.role_definition_resource_substring)
      ? role_assignment.role_definition_id_or_name
      : one(data.azapi_resource_list.role_definition[role_key].output.values).id
    )
  }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

locals {
  has_multiple_address_prefixes = var.address_prefixes != null ? length(var.address_prefixes) > 1 : false
}

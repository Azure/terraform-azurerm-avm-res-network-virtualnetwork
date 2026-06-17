locals {
  # Subscription scope used by the interfaces module to resolve role definition
  # names to resource ids. Derived from the resource group parent_id.
  role_assignment_definition_scope = "/subscriptions/${split("/", var.parent_id)[2]}"
}

locals {
  # Subscription scope used by the interfaces module to resolve role definition
  # names to resource ids. Derived from the resource group parent_id.
  role_assignment_definition_scope = "/subscriptions/${split("/", var.parent_id)[2]}"
  # Subnet keys still using the deprecated `service_endpoints_with_location`
  # attribute, surfaced as a warning by the check block in main.subnet.tf.
  subnets_using_service_endpoints_with_location = [
    for key, subnet in var.subnets : key
    if subnet.service_endpoints_with_location != null
  ]
  # Resolve service endpoints from either the current `service_endpoints`
  # attribute or the deprecated `service_endpoints_with_location`, discarding
  # the locations. Azure expands service-endpoint locations implicitly, so
  # sending them explicitly caused perpetual drift (see issues #22 and #39).
  subnet_service_endpoints = {
    for key, subnet in var.subnets : key => (
      subnet.service_endpoints != null ? subnet.service_endpoints : (
        subnet.service_endpoints_with_location != null
        ? toset([for endpoint in subnet.service_endpoints_with_location : endpoint.service])
        : null
      )
    )
  }
}

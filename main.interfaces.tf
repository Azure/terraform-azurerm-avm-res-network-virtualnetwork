module "avm_interfaces" {
  source = "git::https://github.com/Azure/terraform-azure-avm-utl-interfaces.git?ref=feat/prepv1"
  #version = "0.4.0"

  parent_id        = var.parent_id
  this_resource_id = azapi_resource.vnet.id
  location         = var.location
  enable_telemetry = var.enable_telemetry

  diagnostic_settings = local.diagnostic_settings
  lock                = local.lock
  role_assignments    = var.role_assignments
}

moved {
  from = azapi_resource.lock
  to   = module.avm_interfaces.azapi_resource.locks
}

moved {
  from = azapi_resource.role_assignments
  to   = module.avm_interfaces.azapi_resource.role_assignments
}

moved {
  from = azapi_resource.diagnostic_settings
  to   = module.avm_interfaces.azapi_resource.diagnostic_settings
}

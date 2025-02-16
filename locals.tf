locals {
  subscription_id = coalesce(var.subscription_id, data.azapi_client_config.this.subscription_id)
}

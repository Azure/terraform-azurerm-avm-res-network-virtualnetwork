# Importing the Azure naming module to ensure resources have unique CAF compliant names.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# Creating a resource group with a unique name in the specified location.
resource "azurerm_resource_group" "example" {
  location = var.rg_location
  name     = module.naming.resource_group.name_unique
}

# Creating a virtual network with a unique name, telemetry settings, and in the specified resource group and location.
module "vnet" {
  source              = "../../"
  name                = module.naming.virtual_network.name
  enable_telemetry    = true
  resource_group_name = azurerm_resource_group.example.name
  vnet_location       = var.vnet_location

  # Uncomment the below block to apply a ReadOnly lock to the virtual network.
  /* lock = {
    name = "test-lock"
    kind = "ReadOnly"
  } */

  # 
  /* diagnostic_settings = {
  vnet_diag = {
    name                        = "vnet-diag"
    workspace_resource_id       = "/subscriptions/<subscription _id>/resourceGroups/<resource_group_name>/providers/Microsoft.OperationalInsights/workspaces/<log_analytiics_workspace_name>"
    storage_account_resource_id = "/subscriptions/<subscription _id>/resourceGroups/<resource_group_name>/providers/Microsoft.Storage/storageAccounts/<storage_account_name>"
  } 
} */
}




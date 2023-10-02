# Create a Simple Virtual Network 

This sample code creates a Azure Virtual Network with default values. 
## Resources Provisioned

Azure Resource Group

    Location: Defined by the variable var.rg_location.

    Name: Generated uniquely using the Azure naming module.

Azure Virtual Network

    - Name: Generated uniquely using the Azure naming module.
    - Telemetry: Enabled by default.
    - Location: Defined by the variable var.vnet_location.
    - Resource Group: The name of an existing resource group.

## Optional Settings

ReadOnly Lock: Can be applied by uncommenting the respective block.

Diagnostic Settings: Can be applied by uncommenting the respective block. This setting requires  the necessary resources to be existing on the subscription.

```
diagnostic_settings = {
  vnet_diag = {
    name                        = "vnet-diag"
    workspace_resource_id       = "/subscriptions/<subscription _id>/resourceGroups/<resource_group_name>/providers/Microsoft.OperationalInsights/workspaces/<log_analytiics_workspace_name>"
    storage_account_resource_id = "/subscriptions/<subscription _id>/resourceGroups/<resource_group_name>/providers/Microsoft.Storage/storageAccounts/<storage_account_name>"
  } 
}
```

## Outputs

name: The name of the newly created vNet.

vnet_id: The ID of the newly created vNet.

vnet_address_space: The address space of the newly created vNet.

subnet_names: The names of the newly created subnets.

subnet_address_prefixes: The address prefixes of the newly created subnets.

vnet_location: The location of the newly created vNet.


## Usage

Ensure you have Terraform installed and the Azure CLI authenticated to your Azure subscription.

Define the necessary variables:
 
    var.rg_location
    var.vnet_location

Navigate to the directory containing this configuration and run:

```
terraform init
terraform plan
terraform apply
```
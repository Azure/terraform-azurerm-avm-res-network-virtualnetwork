# Create Azure Virtual Network with Route Tables

This sample code create a Azure Virtual Network with the following resources provisioned.
## Resources Provisioned

    Azure Resource Group:
    Azure Virtual Network:
    Telemetry: Defined by the variable var.enable_telemetry.
    Subnets
    Route Table Association
    Azure Route Table
        Azure Route:
            Address Prefix: 10.1.0.0/16.
            Name: "acceptanceTestRoute1".
            Next Hop Type: "VnetLocal".

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
    var.vnet_location.

Navigate to the directory containing this configuration and run:

```
terraform init
terraform plan
terraform apply
```
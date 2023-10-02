# Create Azure Virtual Network with NSG

This sample code creates a Azure Virtual Network with a Netwrok Security Group (NSG) with SSH access. 

## Resources Provisioned

    Azure Resource Group

    Azure Virtual Network

    Telemetry: Defined by the variable var.enable_telemetry.

    Subnets: Three subnets with specified address prefixes and names.

    Network Security Group Association: The same NSG is associated with all three subnets.

    Public IP Data Source

    Azure Network Security Group (NSG) with SSH Access

    Security Rule: Allows SSH access (port 22) from the executor's IP address.



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
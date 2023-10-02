# Create Azure Virtual Network with specific configurations

This sample create an Azure Virtual Network along with subnets,delegations and network policies.

## Resources Provisioned

    Azure Resource Group:

    Location: Defined by the variable var.rg_location.

    Name: Generated uniquely using the Azure naming module.

    Azure Network Security Group (NSG)

    Azure Route Table

    Azure Virtual Network:

    Subnets: Three subnets with specified address prefixes and names.

    Network Security Group Association: NSG is associated with subnet1.

    Service Endpoints: Specific service endpoints are enabled on subnet1 and subnet2.

    Service Delegation: Configured for subnet1 and subnet2.

    Route Table Association: Route Table is associated with subnet1.

    Private Link Endpoint Network Policies: Enabled on subnet2 and subnet3.


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

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
module "create_vnet" {
  source                        = "../../"
  name                          = module.naming.virtual_network.name
  enable_telemetry              = true
  resource_group_name           = azurerm_resource_group.example.name
  location                      = var.vnet_location
  virtual_network_address_space = ["10.0.0.0/16"]
}

# Call the module again, this time creating and attaching a subnet to simulate a existing vnet

module "create_subnet" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.example.name
  existing_virtual_network = {
    id = module.create_vnet.virtual_network_id
  }
  virtual_network_address_space = ["10.0.0.0/16"]
  location                      = azurerm_resource_group.example.location

  # Define the subnet(s) you want to create within the existing VNet
  subnets = {
    "subnet1" = {
      address_prefixes                              = ["10.0.1.0/24"]
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
      # Add other subnet configurations as required by your module
    }
    # Add more subnets if needed
  }
}


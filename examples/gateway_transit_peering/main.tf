terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = local.selected_region
  name     = module.naming.resource_group.name_unique
}

# Hub virtual network: hosts the VPN gateway and shares it via gateway transit.
resource "azurerm_virtual_network" "hub" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_network.name_unique}-hub"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
}

# The gateway subnet must be named exactly "GatewaySubnet".
resource "azurerm_subnet" "gateway" {
  address_prefixes     = ["10.0.255.0/27"]
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
}

resource "azurerm_public_ip" "gateway" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.public_ip.name_unique}-gw"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
}

# A real VPN gateway is required so that the spoke -> hub reverse peering can set
# use_remote_gateways = true, which is the scenario that reproduces #57.
resource "azurerm_virtual_network_gateway" "hub" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_network_gateway.name_unique}-hub"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "VpnGw1"
  type                = "Vpn"
  vpn_type            = "RouteBased"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.gateway.id
    subnet_id                     = azurerm_subnet.gateway.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Spoke virtual network: uses the hub's gateway via the reverse peering.
resource "azurerm_virtual_network" "spoke" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_network.name_unique}-spoke"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.1.0.0/16"]
}

# Forward (hub -> spoke) sets allow_gateway_transit = true and the reverse
# (spoke -> hub) sets use_remote_gateways = true. Azure validates the reverse
# against the forward peering's allow_gateway_transit at creation time, so the
# forward peering must be fully provisioned first. See #57.
module "peering" {
  source = "../../modules/peering"

  name                                 = "${module.naming.virtual_network_peering.name_unique}-hub-to-spoke"
  parent_id                            = azurerm_virtual_network.hub.id
  remote_virtual_network_id            = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic              = true
  allow_gateway_transit                = true
  allow_virtual_network_access         = true
  create_reverse_peering               = true
  reverse_allow_forwarded_traffic      = true
  reverse_allow_gateway_transit        = false
  reverse_allow_virtual_network_access = true
  reverse_name                         = "${module.naming.virtual_network_peering.name_unique}-spoke-to-hub"
  reverse_use_remote_gateways          = true
  use_remote_gateways                  = false

  depends_on = [azurerm_virtual_network_gateway.hub]
}

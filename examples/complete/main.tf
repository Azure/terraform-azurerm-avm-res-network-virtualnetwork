terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azapi" {}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

# This is required for resource modules
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  location = local.selected_region
  name     = module.naming.resource_group.name_unique
}

#Creating a Route Table with a unique name in the specified location.
resource "azapi_resource" "route_table" {
  location  = module.resource_group.location
  name      = module.naming.route_table.name_unique
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/routeTables@2024-07-01"
  body = {
    properties = {}
  }
  response_export_values = []
}

# Creating a DDoS Protection Plan in the specified location.
resource "azapi_resource" "ddos_protection_plan" {
  location  = module.resource_group.location
  name      = module.naming.network_ddos_protection_plan.name_unique
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/ddosProtectionPlans@2024-07-01"
  body = {
    properties = {}
  }
  response_export_values = []
}

# Creating a NAT Gateway in the specified location.
resource "azapi_resource" "nat_gateway" {
  location  = module.resource_group.location
  name      = module.naming.nat_gateway.name_unique
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/natGateways@2024-07-01"
  body = {
    properties = {
      idleTimeoutInMinutes = 4
    }
    sku = {
      name = "Standard"
    }
  }
  response_export_values = []
}

# Fetching the public IP address of the Terraform executor used for NSG
data "http" "public_ip" {
  method = "GET"
  url    = "http://api.ipify.org?format=json"
}

resource "azapi_resource" "https" {
  location  = module.resource_group.location
  name      = module.naming.network_security_group.name_unique
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/networkSecurityGroups@2024-07-01"
  body = {
    properties = {
      securityRules = [{
        name = "AllowInboundHTTPS"
        properties = {
          access                   = "Allow"
          destinationAddressPrefix = "*"
          destinationPortRange     = "443"
          direction                = "Inbound"
          priority                 = 100
          protocol                 = "Tcp"
          sourceAddressPrefix      = jsondecode(data.http.public_ip.response_body).ip
          sourcePortRange          = "*"
        }
      }]
    }
  }
  response_export_values = []
}

resource "azapi_resource" "identity" {
  location  = module.resource_group.location
  name      = module.naming.user_assigned_identity.name_unique
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  body      = {}

  response_export_values = ["properties.principalId"]
}

resource "azapi_resource" "storage_account" {
  location  = module.resource_group.location
  name      = module.naming.storage_account.name_unique
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  body = {
    kind = "StorageV2"
    properties = {
      allowBlobPublicAccess = false
      allowSharedKeyAccess  = false
    }
    sku = {
      name = "Standard_ZRS"
    }
  }
  response_export_values = []
}

resource "azapi_resource" "service_endpoint_policy" {
  location  = module.resource_group.location
  name      = "sep-${module.naming.unique-seed}"
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/serviceEndpointPolicies@2024-07-01"
  body = {
    properties = {
      serviceEndpointPolicyDefinitions = [{
        name = "name1"
        properties = {
          description = "definition1"
          service     = "Microsoft.Storage"
          serviceResources = [
            module.resource_group.resource_id,
            azapi_resource.storage_account.id
          ]
        }
      }]
    }
  }
  response_export_values = []
}

resource "azapi_resource" "log_analytics_workspace" {
  location  = module.resource_group.location
  name      = module.naming.log_analytics_workspace.name_unique
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.OperationalInsights/workspaces@2023-09-01"
  body = {
    properties = {
      retentionInDays = 30
      sku = {
        name = "PerGB2018"
      }
    }
  }
  response_export_values = []
}

#Defining the first virtual network (vnet-1) with its subnets and settings.
module "vnet1" {
  source = "../../"

  location      = module.resource_group.location
  parent_id     = module.resource_group.resource_id
  address_space = var.address_space_vnet1
  ddos_protection_plan = {
    id = azapi_resource.ddos_protection_plan.id
    # due to resource cost
    enable = false
  }
  diagnostic_settings = {
    sendToLogAnalytics = {
      name                           = "sendToLogAnalytics"
      workspace_resource_id          = azapi_resource.log_analytics_workspace.id
      log_analytics_destination_type = "Dedicated"
    }
  }
  dns_servers = {
    dns_servers = ["8.8.8.8", "1.1.1.1", "1.0.0.1"]
  }
  enable_vm_protection = true
  encryption = {
    enabled = true
    #enforcement = "DropUnencrypted"  # NOTE: This preview feature requires approval, leaving off in example: Microsoft.Network/AllowDropUnecryptedVnet
    enforcement = "AllowUnencrypted"
  }
  flow_timeout_in_minutes = 30
  name                    = module.naming.virtual_network.name_unique
  role_assignments = {
    role1 = {
      principal_id               = azapi_resource.identity.output.properties.principalId
      role_definition_id_or_name = "Contributor"
    }
  }
  subnets = {
    subnet0 = {
      name                            = "${module.naming.subnet.name_unique}0"
      default_outbound_access_enabled = false
      #sharing_scope                   = "Tenant"  #NOTE: This preview feature requires approval, leaving off in example: Microsoft.Network/EnableSharedVNet
      address_prefixes = ["192.168.0.0/24", "192.168.2.0/24"]
    }
    subnet1 = {
      name                            = "${module.naming.subnet.name_unique}1"
      address_prefixes                = ["192.168.1.0/24"]
      default_outbound_access_enabled = false
      delegations = [{
        name = "Microsoft.Web.serverFarms"
        service_delegation = {
          name = "Microsoft.Web/serverFarms"
        }
      }]
      nat_gateway = {
        id = azapi_resource.nat_gateway.id
      }
      network_security_group = {
        id = azapi_resource.https.id
      }
      route_table = {
        id = azapi_resource.route_table.id
      }
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      service_endpoint_policies = {
        policy1 = {
          id = azapi_resource.service_endpoint_policy.id
        }
      }
      role_assignments = {
        role1 = {
          principal_id               = azapi_resource.identity.output.properties.principalId
          role_definition_id_or_name = "Contributor"
        }
      }
    }
  }
}

module "vnet2" {
  source = "../../"

  location      = module.resource_group.location
  parent_id     = module.resource_group.resource_id
  address_space = ["10.0.0.0/27"]
  encryption = {
    enabled     = true
    enforcement = "AllowUnencrypted"
  }
  name = "${module.naming.virtual_network.name_unique}2"
  peerings = {
    peertovnet1 = {
      name                                  = "${module.naming.virtual_network_peering.name_unique}-vnet2-to-vnet1"
      remote_virtual_network_resource_id    = module.vnet1.resource_id
      allow_forwarded_traffic               = true
      allow_gateway_transit                 = true
      allow_virtual_network_access          = true
      do_not_verify_remote_gateways         = false
      enable_only_ipv6_peering              = false
      use_remote_gateways                   = false
      create_reverse_peering                = true
      reverse_name                          = "${module.naming.virtual_network_peering.name_unique}-vnet1-to-vnet2"
      reverse_allow_forwarded_traffic       = false
      reverse_allow_gateway_transit         = false
      reverse_allow_virtual_network_access  = true
      reverse_do_not_verify_remote_gateways = false
      reverse_enable_only_ipv6_peering      = false
      reverse_use_remote_gateways           = false
      sync_remote_address_space_enabled     = true
      sync_remote_address_space_triggers = [
        var.address_space_vnet1,
        var.address_space_vnet2
      ]
    }
  }
}

terraform {
  required_version = ">= 1.9.2"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
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

locals {
  regions = ["eastus2", "westus2", "westeurope"]
}

resource "random_integer" "region_index" {
  max = length(local.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

resource "azurerm_resource_group" "this" {
  location = local.regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

data "azurerm_subscription" "this" {}

# Network Manager and IPAM Pool for mixed scenario
resource "azapi_resource" "network_manager" {
  location  = azurerm_resource_group.this.location
  name      = replace(module.naming.resource_group.name_unique, module.naming.resource_group.slug, "avnm")
  parent_id = azurerm_resource_group.this.id
  type      = "Microsoft.Network/networkManagers@2024-07-01"
  body = {
    properties = {
      networkManagerScopeAccesses = []
      networkManagerScopes = {
        subscriptions = [data.azurerm_subscription.this.id]
      }
    }
  }
  schema_validation_enabled = false
}

resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"

  depends_on = [azapi_resource.network_manager]
}

# IPAM Pool for workload subnets
resource "azapi_resource" "ipam_pool_workloads" {
  location  = azurerm_resource_group.this.location
  name      = "pool-workloads"
  parent_id = azapi_resource.network_manager.id
  type      = "Microsoft.Network/networkManagers/ipamPools@2024-07-01"
  body = {
    properties = {
      addressPrefixes = ["10.100.0.0/16"]
      description     = "IPAM Pool for dynamic workload subnet allocation"
      displayName     = "Workloads Pool"
    }
  }
  schema_validation_enabled = false

  depends_on = [time_sleep.wait_30_seconds]
}

# Network Security Groups
resource "azurerm_network_security_group" "workload" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.network_security_group.name}-workload"
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_ranges    = ["80", "443", "8080"]
    direction                  = "Inbound"
    name                       = "AllowWorkload"
    priority                   = 1001
    protocol                   = "Tcp"
    source_address_prefix      = "10.0.0.0/8"
    source_port_range          = "*"
  }
}

resource "azurerm_network_security_group" "management" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.network_security_group.name}-mgmt"
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "3389"
    direction                  = "Inbound"
    name                       = "AllowRDP"
    priority                   = 1001
    protocol                   = "Tcp"
    source_address_prefix      = "10.100.12.0/24" # Management subnet range
    source_port_range          = "*"
  }
}

# Dedicated NSG for Azure Bastion with required rules
resource "azurerm_network_security_group" "bastion" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.network_security_group.name}-bastion"
  resource_group_name = azurerm_resource_group.this.name

  # Required Azure Bastion inbound rules
  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "443"
    direction                  = "Inbound"
    name                       = "AllowHttpsInbound"
    priority                   = 1000
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "443"
    direction                  = "Inbound"
    name                       = "AllowGatewayManagerInbound"
    priority                   = 1001
    protocol                   = "Tcp"
    source_address_prefix      = "GatewayManager"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "443"
    direction                  = "Inbound"
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 1002
    protocol                   = "Tcp"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["8080", "5701"]
    direction                  = "Inbound"
    name                       = "AllowBastionHostCommunication"
    priority                   = 1003
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
  # Required Azure Bastion outbound rules
  security_rule {
    access                     = "Allow"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["22", "3389"]
    direction                  = "Outbound"
    name                       = "AllowSshRdpOutbound"
    priority                   = 1000
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    destination_address_prefix = "AzureCloud"
    destination_port_range     = "443"
    direction                  = "Outbound"
    name                       = "AllowAzureCloudOutbound"
    priority                   = 1001
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["8080", "5701"]
    direction                  = "Outbound"
    name                       = "AllowBastionCommunication"
    priority                   = 1002
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    destination_address_prefix = "Internet"
    destination_port_range     = "80"
    direction                  = "Outbound"
    name                       = "AllowGetSessionInformation"
    priority                   = 1003
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
  }
}

# Traditional VNet with mixed IPAM and static subnets
module "vnet_mixed" {
  source = "../../"

  location  = azurerm_resource_group.this.location
  parent_id = azurerm_resource_group.this.id
  # DNS servers configuration
  dns_servers = {
    dns_servers = toset(["1.1.1.1", "8.8.8.8"])
  }
  enable_telemetry = true
  # IPAM pool reference for mixed VNet - provides address space for both IPAM and static subnets
  ipam_pools = [{
    id            = azapi_resource.ipam_pool_workloads.id
    prefix_length = 20 # /20 allocation (4096 IPs) to leave space for second VNet
  }]
  name = "${module.naming.virtual_network.name_unique}-mixed"
  # Mixed subnet allocation strategies
  subnets = {
    # Static management subnets (use higher address ranges to avoid IPAM conflicts)
    management = {
      name             = "subnet-management"
      address_prefixes = ["10.100.12.0/24"] # Within IPAM VNet range 0.0/20
      network_security_group = {
        id = azurerm_network_security_group.management.id
      }
      service_endpoints = ["Microsoft.Storage"]
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }

    bastion = {
      name             = "AzureBastionSubnet" # Special Azure Bastion subnet name
      address_prefixes = ["10.100.13.0/26"]   # Within IPAM VNet range 0.0/20
      network_security_group = {
        id = azurerm_network_security_group.bastion.id
      }
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }

    gateway = {
      name             = "GatewaySubnet"     # Special Gateway subnet name
      address_prefixes = ["10.100.13.64/27"] # Within IPAM VNet range 0.0/20
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }

    # IPAM workload subnets (created sequentially with delays)
    web_workload = {
      name = "subnet-web-workload"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool_workloads.id
        prefix_length = 24
      }]
      network_security_group = {
        id = azurerm_network_security_group.workload.id
      }
      service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }

    app_workload = {
      name = "subnet-app-workload"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool_workloads.id
        prefix_length = 24
      }]
      network_security_group = {
        id = azurerm_network_security_group.workload.id
      }
      service_endpoints = ["Microsoft.Storage"]
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }

    data_workload = {
      name = "subnet-data-workload"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool_workloads.id
        prefix_length = 25
      }]
      network_security_group = {
        id = azurerm_network_security_group.workload.id
      }
      service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }

    # Static shared services subnet
    shared_services = {
      name             = "subnet-shared-services"
      address_prefixes = ["10.100.14.0/24"] # Within IPAM VNet range 0.0/20
      network_security_group = {
        id = azurerm_network_security_group.management.id
      }
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }
  }
  tags = {
    Environment = "test"
    Purpose     = "mixed-addressing-demo"
    Scenario    = "ipam-traditional-hybrid"
  }
}

# Demonstrate IPAM VNet alongside traditional VNet
module "vnet_ipam_workloads" {
  source = "../../"

  location         = azurerm_resource_group.this.location
  parent_id        = azurerm_resource_group.this.id
  enable_telemetry = true
  # Pure IPAM VNet for scalable workloads
  ipam_pools = [{
    id            = azapi_resource.ipam_pool_workloads.id
    prefix_length = 20 # Larger space for many workload subnets
  }]
  name = "${module.naming.virtual_network.name_unique}-ipam-workloads"
  # All IPAM subnets for dynamic workload deployment
  subnets = {
    microservice_1 = {
      name = "subnet-microservice-1"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool_workloads.id
        prefix_length = 26
      }]
      network_security_group = {
        id = azurerm_network_security_group.workload.id
      }
      service_endpoints = ["Microsoft.Storage"]
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }

    microservice_2 = {
      name = "subnet-microservice-2"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool_workloads.id
        prefix_length = 26
      }]
      network_security_group = {
        id = azurerm_network_security_group.workload.id
      }
      service_endpoints = ["Microsoft.Storage"]
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }

    microservice_3 = {
      name = "subnet-microservice-3"
      ipam_pools = [{
        pool_id       = azapi_resource.ipam_pool_workloads.id
        prefix_length = 27
      }]
      network_security_group = {
        id = azurerm_network_security_group.workload.id
      }
      # Enhanced retry configuration for Azure operation conflicts
      retry = {
        error_message_regex = [
          "AnotherOperationInProgress",
          "ReferencedResourceNotProvisioned",
          "OperationNotAllowed"
        ]
        interval_seconds     = 30
        max_interval_seconds = 300
      }
    }
  }
  tags = {
    Environment = "test"
    Purpose     = "pure-ipam-workloads"
    Scenario    = "scalable-microservices"
  }
}

# Peering between traditional and IPAM VNets
module "vnet_peering" {
  source = "../../modules/peering"

  name                         = "mixed-to-ipam"
  parent_id                    = module.vnet_mixed.resource_id
  remote_virtual_network_id    = module.vnet_ipam_workloads.resource_id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  allow_virtual_network_access = true
  use_remote_gateways          = false

  depends_on = [
    module.vnet_mixed,
    module.vnet_ipam_workloads
  ]
}

mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  name      = "subnet-unit-test"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
  location  = "eastus"
}

run "static_default_keeps_existing_address" {
  command = plan
  variables { address_prefixes = ["10.0.0.0/24"] }
  assert {
    condition     = length(azapi_resource.subnet) == 1 && length(azapi_resource.subnet_nsg_external) == 0
    error_message = "A subnet without NSG exclusion must retain its existing resource address."
  }
}

run "static_external_nsg" {
  command = plan
  variables {
    address_prefixes                          = ["10.0.0.0/24"]
    network_security_group_managed_externally = true
  }
  assert {
    condition     = length(azapi_resource.subnet) == 0 && length(azapi_resource.subnet_nsg_external) == 1
    error_message = "Only the NSG exclusion should select the protected subnet resource."
  }
}

run "ipam_default_keeps_existing_address" {
  command = plan
  variables {
    ipam_pools = [{ pool_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/test-pool", prefix_length = 24 }]
  }
  assert {
    condition     = length(azapi_resource.subnet_ipam) == 1 && length(azapi_resource.subnet_ipam_nsg_external) == 0
    error_message = "An IPAM subnet without NSG exclusion must retain its existing resource address."
  }
}

run "ipam_external_nsg" {
  command = plan
  variables {
    ipam_pools                                = [{ pool_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/test-pool", prefix_length = 24 }]
    network_security_group_managed_externally = true
  }
  assert {
    condition     = length(azapi_resource.subnet_ipam) == 0 && length(azapi_resource.subnet_ipam_nsg_external) == 1
    error_message = "The IPAM subnet should use its protected resource when NSG changes are excluded."
  }
}

run "external_nsg_rejects_duplicate_owner" {
  command = plan
  variables {
    address_prefixes                          = ["10.0.0.0/24"]
    network_security_group_managed_externally = true
    network_security_group = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkSecurityGroups/test-nsg"
    }
  }
  expect_failures = [azapi_resource.subnet_nsg_external[0]]
}

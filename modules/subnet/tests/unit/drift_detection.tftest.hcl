# Unit tests for subnet out-of-band drift detection (issue #62).
#
# Runs at plan time with a mocked azapi provider - no Azure resources are
# deployed. Execute with: avm test unit
#
# Guards #62: the subnet resources must set `ignore_missing_property = false`
# so that when an out-of-band controller (AVNM `ManagedOnly` routing or an
# Azure Policy DINE assignment) removes a body property the module manages
# (for example `properties.routeTable`), Terraform surfaces the removal as
# drift and offers to restore it, rather than silently swallowing it.
#
# When an operator deliberately wants an external controller to own a path,
# they pair this with `ignore_body_changes` (issue #61 / TFFR8) to suppress
# the drift for that specific path only.

mock_provider "azapi" {}

variables {
  name      = "subnet-unit-test"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
}

# Traditional (non-IPAM) subnet must detect removal of managed properties.
run "traditional_subnet_detects_drift" {
  command = plan

  variables {
    address_prefixes = ["10.0.0.0/24"]
  }

  assert {
    condition     = azapi_resource.subnet[0].ignore_missing_property == false
    error_message = "The non-IPAM subnet must set ignore_missing_property = false so out-of-band removal of a managed body property (e.g. properties.routeTable) is surfaced as drift."
  }
}

# IPAM subnet must detect removal of managed properties on the same path.
run "ipam_subnet_detects_drift" {
  command = plan

  variables {
    ipam_pools = [{
      pool_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/test-pool"
      prefix_length = 24
    }]
  }

  assert {
    condition     = azapi_resource.subnet_ipam[0].ignore_missing_property == false
    error_message = "The IPAM subnet must set ignore_missing_property = false so out-of-band removal of a managed body property is surfaced as drift."
  }
}

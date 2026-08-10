# Unit tests for the subnet `ignore_body_changes` input.
# Runs at plan time with mocked providers - no Azure resources are deployed.
# Execute with: avm test unit
#
# Backs #70 / #61: AVNM `ManagedOnly` routing (and Azure Policy DINE) attach a
# route table to a subnet out-of-band, which the module's `azapi_resource`
# would otherwise re-assert to null, producing perpetual `terraform plan` drift.
# Setting `ignore_body_changes = ["properties.routeTable"]` lets the external
# controller own that property. `ignore_body_changes` is a write-only azapi
# argument (stored in provider-private state, requires Terraform >= 1.11) so its
# value cannot be read back at plan time; these tests instead assert that the
# input is accepted, cascades to both the standard and IPAM subnet resources,
# and does not strip the configured body.

mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  name             = "vnet-unit-test"
  location         = "westeurope"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
  enable_telemetry = false
  address_space    = ["10.0.0.0/16"]
}

# Setting ignore_body_changes on a standard subnet must plan cleanly and must not
# strip the configured routeTable from the request body (config is still sent on
# create; only future out-of-band changes are ignored).
run "standard_subnet_accepts_ignore_body_changes" {
  command = plan

  variables {
    subnets = {
      test = {
        name             = "snet-ignore"
        address_prefixes = ["10.0.0.0/24"]
        route_table = {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/rt-test"
        }
        ignore_body_changes = ["properties.routeTable"]
      }
    }
  }

  assert {
    condition     = module.subnet["test"].resource.body.properties.routeTable.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/rt-test"
    error_message = "routeTable must remain in the subnet body when ignore_body_changes is set - the flag suppresses future drift, it does not strip configuration."
  }
}

# The same input must be accepted on the IPAM subnet code path.
run "ipam_subnet_accepts_ignore_body_changes" {
  command = plan

  variables {
    subnets = {
      test = {
        name = "snet-ipam-ignore"
        ipam_pools = [
          {
            pool_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/nm-test/ipamPools/pool-test"
            prefix_length = 24
          }
        ]
        ignore_body_changes = ["properties.routeTable", "properties.networkSecurityGroup"]
      }
    }
  }

  assert {
    condition     = length(module.subnet["test"].resource.body.properties.ipamPoolPrefixAllocations) == 1
    error_message = "IPAM subnet must still plan its pool allocation when ignore_body_changes is set."
  }
}

# The default must be an empty list so existing configurations are unaffected.
run "default_is_empty_list" {
  command = plan

  variables {
    subnets = {
      test = {
        name             = "snet-default"
        address_prefixes = ["10.0.0.0/24"]
      }
    }
  }

  assert {
    condition     = var.subnets["test"].ignore_body_changes == null || length(coalesce(var.subnets["test"].ignore_body_changes, [])) == 0
    error_message = "ignore_body_changes must default to an empty list on the subnets schema."
  }
}

# The module-wide shared slot (root ignore_body_changes.virtual_networks_subnets)
# must cascade to every subnet that has no per-item override, without stripping
# configured body.
run "shared_subnet_slot_cascades" {
  command = plan

  variables {
    ignore_body_changes = {
      virtual_networks_subnets = {
        virtual_networks_subnets = ["properties.routeTable"]
      }
    }
    subnets = {
      test = {
        name             = "snet-shared"
        address_prefixes = ["10.0.0.0/24"]
        route_table = {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/rt-test"
        }
      }
    }
  }

  assert {
    condition     = module.subnet["test"].resource.body.properties.routeTable.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/rt-test"
    error_message = "routeTable must remain in the subnet body when the shared ignore_body_changes slot is set."
  }
}

# A top-level path may be ignored on the virtual network itself (for example
# tags applied by Azure Policy). The vnet must still plan its address space.
run "vnet_level_ignore_accepted" {
  command = plan

  variables {
    ignore_body_changes = {
      virtual_networks = ["tags"]
    }
    subnets = {}
  }

  assert {
    condition     = contains(azapi_resource.vnet.body.properties.addressSpace.addressPrefixes, "10.0.0.0/16")
    error_message = "The virtual network must still plan its address space when ignore_body_changes.virtual_networks is set."
  }
}

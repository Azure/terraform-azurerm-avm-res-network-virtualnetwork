# Unit tests for the removed `service_endpoints_with_location` subnet attribute.
# Runs at plan time with mocked providers - no Azure resources are deployed.
# Execute with: ./avm tf-test-unit
#
# `subnets` is a map of an object type, and Terraform silently discards
# attributes that are not part of an object type constraint during conversion.
# Without a guard, a consumer upgrading from a release that had
# `service_endpoints_with_location` would have that attribute dropped with no
# error, and the resulting plan would quietly propose removing every service
# endpoint from their subnets. The attribute is therefore still declared, with
# a validation that turns that silent drop into an explanatory failure.

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

# The replacement attribute must plan cleanly.
run "service_endpoints_accepted" {
  command = plan

  variables {
    subnets = {
      subnet0 = {
        name              = "subnet0"
        address_prefix    = "10.0.0.0/24"
        service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
      }
    }
  }
}

# Omitting service endpoints entirely must also plan cleanly, proving the guard
# does not fire on unset values.
run "service_endpoints_omitted" {
  command = plan

  variables {
    subnets = {
      subnet0 = {
        name           = "subnet0"
        address_prefix = "10.0.0.0/24"
      }
    }
  }
}

# The removed attribute must fail loudly rather than being silently discarded.
run "service_endpoints_with_location_rejected" {
  command = plan

  variables {
    subnets = {
      subnet0 = {
        name           = "subnet0"
        address_prefix = "10.0.0.0/24"
        service_endpoints_with_location = [
          {
            service = "Microsoft.Storage"
          }
        ]
      }
    }
  }

  expect_failures = [var.subnets]
}

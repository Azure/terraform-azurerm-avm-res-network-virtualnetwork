# Unit tests for the deprecated `service_endpoints_with_location` subnet attribute.
# Runs at plan time with mocked providers - no Azure resources are deployed.
# Execute with: ./avm tf-test-unit
#
# `subnets` is a map of an object type, and Terraform silently discards
# attributes that are not part of an object type constraint during conversion.
# If the attribute were simply deleted, a consumer upgrading from a release that
# had `service_endpoints_with_location` would have it dropped with no error, and
# the resulting plan would quietly propose removing every service endpoint from
# their subnets. The attribute is therefore still declared and still honoured -
# the service names are mapped through and the locations discarded - so that
# upgrading warns rather than breaks.

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

# The replacement attribute must plan cleanly and be passed through unchanged.
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

  assert {
    condition     = local.subnet_service_endpoints["subnet0"] == toset(["Microsoft.Storage", "Microsoft.Sql"])
    error_message = "service_endpoints should be passed through unchanged."
  }
}

# Omitting service endpoints entirely must also plan cleanly and resolve to null.
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

  assert {
    condition     = local.subnet_service_endpoints["subnet0"] == null
    error_message = "Omitting both attributes should resolve to null."
  }
}

# The deprecated attribute must still be honoured: service names are mapped
# through and the locations are discarded, so upgrading does not break.
run "service_endpoints_with_location_still_honoured" {
  command = plan

  variables {
    subnets = {
      subnet0 = {
        name           = "subnet0"
        address_prefix = "10.0.0.0/24"
        service_endpoints_with_location = [
          {
            service   = "Microsoft.Storage"
            locations = ["westeurope", "northeurope"]
          },
          {
            service = "Microsoft.Sql"
          }
        ]
      }
    }
  }

  assert {
    condition     = local.subnet_service_endpoints["subnet0"] == toset(["Microsoft.Storage", "Microsoft.Sql"])
    error_message = "Deprecated attribute should map service names through, discarding locations."
  }

  assert {
    condition     = local.subnets_using_service_endpoints_with_location == ["subnet0"]
    error_message = "Subnets using the deprecated attribute should be flagged for the deprecation warning."
  }

  # The deprecation warning is emitted by a check block. `terraform test`
  # surfaces a failing check assertion as a test failure, so it is expected
  # here; during a normal plan or apply it is only a warning and does not
  # affect the exit code.
  expect_failures = [check.subnet_service_endpoints_with_location_deprecated]
}

# Setting both attributes on the same subnet is a genuine conflict and must fail.
run "both_attributes_rejected" {
  command = plan

  variables {
    subnets = {
      subnet0 = {
        name              = "subnet0"
        address_prefix    = "10.0.0.0/24"
        service_endpoints = ["Microsoft.Storage"]
        service_endpoints_with_location = [
          {
            service = "Microsoft.Sql"
          }
        ]
      }
    }
  }

  expect_failures = [var.subnets]
}

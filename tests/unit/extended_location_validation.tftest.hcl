# Unit tests for the root `extended_location` variable validation.
# Runs at plan time with mocked providers - no Azure resources are deployed.
# Execute with: ./avm tf-test-unit
#
# Guards #54: the validation previously called contains("EdgeZone", ...) which
# passed a string as the first argument and crashed for any non-null
# extended_location. It must accept a valid EdgeZone and reject other types.

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

# --- Valid configurations (plan must succeed) ---

run "valid_extended_location_edgezone" {
  command = plan

  variables {
    extended_location = {
      name = "microsoftrrdclab1"
      type = "EdgeZone"
    }
  }
}

run "valid_extended_location_null" {
  command = plan

  variables {
    extended_location = null
  }
}

# --- Invalid configuration (plan must fail validation) ---

run "invalid_extended_location_type" {
  command = plan

  variables {
    extended_location = {
      name = "Perth"
      type = "NotAnEdgeZone"
    }
  }

  expect_failures = [var.extended_location]
}

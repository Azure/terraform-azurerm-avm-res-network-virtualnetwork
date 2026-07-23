# Unit tests for `private_endpoint_network_policies` on subnets.
# Runs at plan time with mocked providers - no Azure resources are deployed.
# Execute with: ./avm tf-test-unit
#
# Guards #46: some regions (e.g. South Africa West) reject the
# `privateEndpointNetworkPolicies` property outright. Setting
# `private_endpoint_network_policies_enabled = false` must omit the property
# from the request body entirely, while the default (true) must keep the
# backward-compatible `Enabled` value being sent.

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

# Disabling the gate must omit the property from the body so unsupported regions accept the request.
run "disabled_gate_omits_property" {
  command = plan

  variables {
    subnets = {
      test = {
        name                                      = "snet-omit"
        address_prefixes                          = ["10.0.0.0/24"]
        private_endpoint_network_policies_enabled = false
      }
    }
  }

  assert {
    condition     = !can(module.subnet["test"].resource.body.properties.privateEndpointNetworkPolicies)
    error_message = "privateEndpointNetworkPolicies must be omitted from the body when private_endpoint_network_policies_enabled is false."
  }
}

# An explicit value must be sent through unchanged when the gate is enabled (default).
run "explicit_value_is_sent" {
  command = plan

  variables {
    subnets = {
      test = {
        name                              = "snet-set"
        address_prefixes                  = ["10.0.0.0/24"]
        private_endpoint_network_policies = "Disabled"
      }
    }
  }

  assert {
    condition     = module.subnet["test"].resource.body.properties.privateEndpointNetworkPolicies == "Disabled"
    error_message = "privateEndpointNetworkPolicies must equal the explicit value when set and the gate is enabled."
  }
}

# Omitting both values must keep the backward-compatible Enabled default in the body.
run "default_is_enabled" {
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
    condition     = module.subnet["test"].resource.body.properties.privateEndpointNetworkPolicies == "Enabled"
    error_message = "privateEndpointNetworkPolicies must default to Enabled when both values are omitted."
  }
}

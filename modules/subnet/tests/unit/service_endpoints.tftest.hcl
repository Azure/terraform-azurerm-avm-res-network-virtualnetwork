# Unit tests for subnet `service_endpoints` (names-only) wiring.
# Runs at plan time with a mocked azapi provider - no Azure resources are
# deployed. Execute with: ./avm tf-test-unit
#
# Guards #22/#39: service endpoints must be emitted as names-only objects
# ({ service = <name> }) with NO `locations` key, and the serviceEndpoints
# list must be matched by the `service` field via `list_unique_id_property`
# so that server-side ordering and Azure's implicit location expansion do not
# produce perpetual drift.

mock_provider "azapi" {}

variables {
  name      = "subnet-unit-test"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
}

# Traditional (non-IPAM) subnet: body must contain names-only service endpoints
# and the list_unique_id_property must key the list by `service`.
run "traditional_subnet_names_only" {
  command = plan

  variables {
    address_prefixes  = ["10.0.0.0/24"]
    service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
  }

  assert {
    condition     = length(azapi_resource.subnet[0].body.properties.serviceEndpoints) == 2
    error_message = "Expected two service endpoints in the subnet body."
  }

  assert {
    condition     = toset([for e in azapi_resource.subnet[0].body.properties.serviceEndpoints : e.service]) == toset(["Microsoft.Storage", "Microsoft.Sql"])
    error_message = "Service endpoints should be emitted using the service names only."
  }

  # The item must NOT carry a `locations` key - that is the source of #39 drift.
  assert {
    condition     = !can(azapi_resource.subnet[0].body.properties.serviceEndpoints[0].locations)
    error_message = "Service endpoint body must not include a locations key."
  }

  assert {
    condition     = azapi_resource.subnet[0].list_unique_id_property["properties.serviceEndpoints"] == "service"
    error_message = "serviceEndpoints list must be matched by the service field."
  }
}

# IPAM subnet: the same names-only mapping and list matching must apply on the
# subnet_ipam resource path.
run "ipam_subnet_names_only" {
  command = plan

  variables {
    ipam_pools = [{
      pool_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkManagers/test-nm/ipamPools/test-pool"
      prefix_length = 24
    }]
    service_endpoints = ["Microsoft.KeyVault"]
  }

  assert {
    condition     = azapi_resource.subnet_ipam[0].body.properties.serviceEndpoints[0].service == "Microsoft.KeyVault"
    error_message = "IPAM subnet service endpoint should be emitted using the service name only."
  }

  assert {
    condition     = !can(azapi_resource.subnet_ipam[0].body.properties.serviceEndpoints[0].locations)
    error_message = "IPAM subnet service endpoint body must not include a locations key."
  }

  assert {
    condition     = azapi_resource.subnet_ipam[0].list_unique_id_property["properties.serviceEndpoints"] == "service"
    error_message = "IPAM subnet serviceEndpoints list must be matched by the service field."
  }
}

# Duplicate service names collapse: `set(string)` structurally de-duplicates,
# so a repeated name yields a single service endpoint in the body.
run "duplicate_service_names_deduped" {
  command = plan

  variables {
    address_prefixes  = ["10.0.0.0/24"]
    service_endpoints = ["Microsoft.Storage", "Microsoft.Storage"]
  }

  assert {
    condition     = length(azapi_resource.subnet[0].body.properties.serviceEndpoints) == 1
    error_message = "Duplicate service names should collapse to a single service endpoint."
  }
}

# `set(string)` normalises input into a canonical (lexicographic) order, so the
# order a consumer happens to write the endpoints in cannot churn the request
# body. Here the input is deliberately NOT in alphabetical order; the emitted
# body must still come out sorted.
#
# Note this covers the module's half of the ordering guarantee only. The other
# half - that the order *Azure* returns cannot cause drift - lives in the azapi
# provider, which matches list items by `service` via `list_unique_id_property`
# rather than by position. That path needs a real API response, so it cannot be
# exercised under `mock_provider`; it is covered instead by the idempotency
# check (apply, then assert an empty plan) in the `service_endpoints` example.
run "input_order_is_normalised" {
  command = plan

  variables {
    address_prefixes = ["10.0.0.0/24"]
    service_endpoints = [
      "Microsoft.Storage",
      "Microsoft.AzureCosmosDB",
      "Microsoft.Web",
      "Microsoft.KeyVault",
    ]
  }

  assert {
    condition = [
      for endpoint in azapi_resource.subnet[0].body.properties.serviceEndpoints : endpoint.service
      ] == [
      "Microsoft.AzureCosmosDB",
      "Microsoft.KeyVault",
      "Microsoft.Storage",
      "Microsoft.Web",
    ]
    error_message = "Service endpoints should be emitted in a canonical sorted order regardless of input order."
  }
}

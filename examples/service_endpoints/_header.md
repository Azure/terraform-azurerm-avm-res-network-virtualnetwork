# Service Endpoints Example

This example demonstrates how to associate service endpoints with subnets using the `service_endpoints` input (a list of service names).

## Features Demonstrated

- Associating multiple service endpoints with a subnet.
- Using the `Microsoft.Storage.Global` cross-region service endpoint.

## Idempotency

Service endpoint locations are intentionally not configurable. Azure implicitly expands service-endpoint locations (for example, `Microsoft.Storage` in a region also adds its paired region), so sending locations explicitly caused perpetual drift. Specifying service names only keeps plans idempotent. See issues #22 and #39 for background.

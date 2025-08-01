# Service Endpoints with Locations Example

This example demonstrates how to configure service endpoints with specific Azure regions (locations) for subnet-level service endpoints.

## Features Demonstrated

- All known service endpoints are supported.

## Idempotency

When using `Microsoft.Storage` or `Microsoft.Sql`, you must specify the `locations` attribute to ensure idempotency. This is crucial for maintaining consistent configurations across deployments:

- Storage - use deployment region + paired region
- SQL - use deployment region only

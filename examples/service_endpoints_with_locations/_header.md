# Service Endpoints with Locations Example

This example demonstrates how to configure service endpoints with specific Azure regions (locations) for subnet-level service endpoints.

## Features Demonstrated

- Virtual network with subnets
- Service endpoints with location restrictions
- Both legacy string format and new object format with locations
- Service endpoints for Storage and Key Vault services

## Key Configuration

The example shows different ways to configure service endpoints:

1. **Legacy format**: Simple string list (backward compatibility)
2. **New format with specific regions**: Restrict service endpoint to specific Azure regions
3. **New format with all regions**: Use "*" to allow all regions

This enables fine-grained control over which Azure regions your service endpoints can access, which is useful for:
- Compliance requirements
- Data residency policies
- Performance optimization
- Security boundaries

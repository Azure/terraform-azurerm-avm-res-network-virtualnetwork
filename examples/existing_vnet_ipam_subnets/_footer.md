## Usage

Ensure you have Terraform installed and the Azure CLI authenticated to your Azure subscription.

Navigate to the directory containing this configuration and run:

```
terraform init
terraform plan
terraform apply
```

### Important Notes

- **IPAM Regional Availability**: Ensure your target Azure region supports IPAM functionality
- **Network Manager Permissions**: Your Azure account must have permissions to create Network Managers
- **IPAM Pool Management**: The example creates its own IPAM pool, but in production you'd typically reference existing pools
- **Address Space Planning**: When using traditional subnets in IPAM VNets, ensure they fit within the dynamically allocated space

### Testing the Enhanced Subnet Module

This example validates:
1. **IPAM subnet creation** using the subnet module with existing IPAM-enabled VNets
2. **Traditional subnet creation** within the same existing IPAM VNet
3. **Feature compatibility** - NSGs, service endpoints work with both addressing methods
4. **Module consistency** - Same interface for adding subnets to existing infrastructure

After deployment, verify in the Azure Portal:
- **Network Manager IPAM**: Shows the IPAM subnet allocation
- **Virtual Network**: Displays both subnets with their respective configurations  
- **Subnet details**: Confirm IP ranges and associated resources are correct

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

## AVM Versioning Notice

Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to https://semver.org/
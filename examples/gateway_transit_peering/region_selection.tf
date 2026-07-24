module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

  # AZ VPN gateway SKUs (VpnGw1AZ) require zone-configured Standard public IPs,
  # so restrict region selection to regions that support availability zones.
  has_availability_zones = true
  is_recommended         = true
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

locals {
  selected_region = module.regions.regions[random_integer.region_index.result].name
}

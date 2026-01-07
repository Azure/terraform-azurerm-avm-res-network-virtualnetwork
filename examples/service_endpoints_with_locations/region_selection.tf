module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.0"

  has_pair       = true
  is_recommended = true
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

locals {
  selected_region = module.regions.regions[random_integer.region_index.result]
}

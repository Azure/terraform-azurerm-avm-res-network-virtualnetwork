module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

  has_pair       = true
  is_recommended = true
  # Exclude Azure canary/EUAP regions (for example eastus2euap, centraluseuap),
  # which are not generally available for resource deployment. This prevents
  # spurious LocationNotAvailable failures when the example e2e tests randomly
  # select a region.
  region_name_regex      = "euap$"
  region_name_regex_mode = "not_match"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

locals {
  selected_region = module.regions.regions[random_integer.region_index.result]
}

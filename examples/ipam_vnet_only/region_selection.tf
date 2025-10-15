module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.working_regions_from_module) - 1
  min = 0
}

locals {
  selected_region = local.working_regions_from_module[random_integer.region_index.result]
  # Regions that allow resource group and avnm ipam creation as of 15-Oct-2025
  working_regions = [
    "eastus2",
    "westus2",
    "eastus",
    "westeurope",
    "uksouth",
    "northeurope",
    "centralus",
    "australiaeast",
    "westus",
    "southcentralus",
    "francecentral",
    "southafricanorth",
    "swedencentral",
    "centralindia",
    "eastasia",
    "canadacentral",
    "germanywestcentral",
    "italynorth",
    "norwayeast",
    "polandcentral",
    "switzerlandnorth",
    "uaenorth",
    "brazilsouth",
    "israelcentral",
    "northcentralus",
    "australiacentral",
    "australiacentral2",
    "australiasoutheast",
    "southindia",
    "canadaeast",
    "germanynorth",
    "norwaywest",
    "switzerlandwest",
    "ukwest",
    "uaecentral",
    "brazilsoutheast",
    "mexicocentral",
    "spaincentral",
    "japaneast",
    "koreasouth",
    "koreacentral",
    "newzealandnorth",
    "southeastasia",
    "japanwest",
    "westcentralus",
    "austriaeast"
  ]
  working_regions_from_module = [
    for region in module.regions.regions : region.name if contains(local.working_regions, region.name)
  ]
}

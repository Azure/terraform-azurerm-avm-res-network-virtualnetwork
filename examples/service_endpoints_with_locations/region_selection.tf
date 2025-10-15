module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.0"

  has_pair       = true
  is_recommended = true
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.working_regions_from_module) - 1
  min = 0
}

locals {
  selected_region = local.working_regions_from_module[random_integer.region_index.result]
  # Regions that allow resource group creation as of 15-Oct-2025
  working_regions = [
    "australiacentral",
    "australiaeast",
    "australiasoutheast",
    "brazilsouth",
    "canadacentral",
    "canadaeast",
    "centralindia",
    "centralus",
    "eastasia",
    "eastus2",
    "eastus",
    "francecentral",
    "germanywestcentral",
    "japaneast",
    "japanwest",
    "jioindiawest",
    "koreacentral",
    "koreasouth",
    "northcentralus",
    "northeurope",
    "norwayeast",
    "southafricanorth",
    "southcentralus",
    "southindia",
    "southeastasia",
    "swedencentral",
    "switzerlandnorth",
    "uaenorth",
    "uksouth",
    "ukwest",
    "westcentralus",
    "westeurope",
    "westindia",
    "westus2",
    "westus3",
    "westus",
    "qatarcentral",
    "israelcentral",
    "polandcentral",
    "italynorth",
    "spaincentral",
    "mexicocentral",
    "austriaeast",
    "chilecentral",
    "malaysiawest",
    "newzealandnorth",
    "indonesiacentral",
    "australiacentral2"
  ]
  working_regions_from_module = [
    for region in module.regions.regions : {
      name               = region.name
      paired_region_name = region.paired_region_name
    } if contains(local.working_regions, region.name)
  ]
}

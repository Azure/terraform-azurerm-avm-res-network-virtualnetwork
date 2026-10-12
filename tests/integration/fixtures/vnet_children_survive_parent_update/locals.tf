locals {
  selected_region = module.regions.regions[random_integer.region_index.result].name
}

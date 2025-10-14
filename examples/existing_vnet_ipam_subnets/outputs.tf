output "ipam_subnet_address_prefixes" {
  description = "The dynamically allocated address prefixes for the IPAM subnet"
  value       = module.ipam_subnet.address_prefixes
}

output "ipam_subnet_id" {
  description = "The resource ID of the IPAM subnet"
  value       = module.ipam_subnet.resource_id
}

output "subnet_module_ipam_comparison" {
  description = "Comparison of IPAM vs traditional subnet addressing"
  value = {
    ipam_subnet = {
      id               = module.ipam_subnet.resource_id
      name             = module.ipam_subnet.name
      address_prefixes = module.ipam_subnet.address_prefixes
      allocation_type  = "IPAM Dynamic"
    }
    traditional_subnet = {
      id               = module.traditional_subnet.resource_id
      name             = module.traditional_subnet.name
      address_prefixes = module.traditional_subnet.address_prefixes
      allocation_type  = "Traditional Explicit"
    }
  }
}

output "traditional_subnet_address_prefixes" {
  description = "The explicitly configured address prefixes for the traditional subnet"
  value       = module.traditional_subnet.address_prefixes
}

output "traditional_subnet_id" {
  description = "The resource ID of the traditional subnet"
  value       = module.traditional_subnet.resource_id
}

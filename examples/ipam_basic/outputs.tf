output "conflict_resolution_status" {
  description = "Status indicating whether IPAM conflicts were resolved through retry logic"
  value       = "If you see this output, retry logic successfully resolved any IPAM allocation conflicts!"
}

output "test_results" {
  description = "Results of the IPAM retry test - shows if conflicts were resolved automatically"
  value = {
    vnet_address_space = tolist(module.vnet_retry_test.address_spaces)[0]
    subnet_allocations = {
      for k, v in module.vnet_retry_test.subnets : k => {
        name              = v.name
        address_prefixes  = v.address_prefixes
        allocation_method = "IPAM with retry logic"
      }
    }
    test_summary = {
      total_subnets     = length(module.vnet_retry_test.subnets)
      deployment_method = "Simultaneous IPAM allocation with retry"
      timing            = "All subnets started at t=0 (no delays)"
    }
  }
}

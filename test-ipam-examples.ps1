#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Full end-to-end test of IPAM examples in the Azure Virtual Network module
.DESCRIPTION
    This script supports multiple testing modes:
    - Run all examples with validation only
    - Run individual examples with full apply/destroy cycle
    - Run all examples with apply, then separately run destroy
.PARAMETER SkipApply
    Skip the apply/destroy phases and only run validation tests (init, validate, plan)
.PARAMETER ManualVerification
    Pause after apply to allow manual verification in Azure Portal before destroying
.PARAMETER ExampleName
    Run only the specified example. Valid values: ipam_basic, ipam_vnet_only, ipam_subnets, ipam_mixed, ipam_full
    Supports tab completion for easy selection
.PARAMETER ApplyOnly
    Only run the apply phase for examples (init, validate, plan, apply)
.PARAMETER DestroyOnly
    Only run the destroy phase for examples (assumes resources are already deployed)
.PARAMETER DestroyRetries
    Number of retry attempts for destroy operations (default: 3). Azure resources sometimes need multiple attempts due to dependency ordering
.PARAMETER ListExamples
    Show available example names and exit
.EXAMPLE
    .\test-ipam-examples.ps1 -SkipApply
    Run validation tests only on all examples
.EXAMPLE
    .\test-ipam-examples.ps1 -ExampleName "ipam_basic"
    Run full end-to-end test on ipam_basic example only
.EXAMPLE
    .\test-ipam-examples.ps1 -ApplyOnly
    Deploy all examples but don't destroy them
.EXAMPLE
    .\test-ipam-examples.ps1 -DestroyOnly
    Destroy all previously deployed examples
.EXAMPLE
    .\test-ipam-examples.ps1 -ExampleName "ipam_vnet_only" -ApplyOnly
    Deploy only the ipam_vnet_only example
.EXAMPLE
    .\test-ipam-examples.ps1 -ExampleName "ipam_vnet_only" -DestroyOnly -DestroyRetries 5
    Destroy only the ipam_vnet_only example with up to 5 retry attempts
.EXAMPLE
    .\test-ipam-examples.ps1 -ListExamples
    Show all available example names
#>

[CmdletBinding()]
param(
    [switch]$SkipApply,
    [switch]$ManualVerification,
    [ValidateSet("ipam_basic", "ipam_vnet_only", "ipam_subnets", "ipam_mixed", "ipam_full")]
    [string]$ExampleName,
    [switch]$ApplyOnly,
    [switch]$DestroyOnly,
    [ValidateRange(1, 10)]
    [int]$DestroyRetries = 3,
    [switch]$ListExamples
)

# Define the IPAM examples to test in order of complexity
$IpamExamples = @(
    @{
        Name = "ipam_basic"
        Description = "Basic IPAM - VNet address space from pools with static subnets"
        Path = "examples\ipam_basic"
    },
    @{
        Name = "ipam_vnet_only"
        Description = "IPAM VNet Only - IPAM for VNet, traditional subnets"
        Path = "examples\ipam_vnet_only"
    },
    @{
        Name = "ipam_subnets"
        Description = "IPAM Subnets - Time-delayed sequential subnet creation"
        Path = "examples\ipam_subnets"
    },
    @{
        Name = "ipam_mixed"
        Description = "IPAM Mixed - Real-world mixed addressing scenarios"
        Path = "examples\ipam_mixed"
    },
    @{
        Name = "ipam_full"
        Description = "IPAM Full - Comprehensive IPAM deployment with all features"
        Path = "examples\ipam_full"
    }
)

# Test results storage
$TestResults = @()
$OverallSuccess = $true

# Validate parameter combinations
if ($SkipApply -and ($ApplyOnly -or $DestroyOnly)) {
    Write-Error "❌ Cannot use -SkipApply with -ApplyOnly or -DestroyOnly"
    exit 1
}

if ($ApplyOnly -and $DestroyOnly) {
    Write-Error "❌ Cannot use -ApplyOnly and -DestroyOnly together"
    exit 1
}

# Show available examples and exit if requested
if ($ListExamples) {
    Write-Host "📋 Available IPAM Examples:" -ForegroundColor Cyan
    foreach ($example in $IpamExamples) {
        Write-Host "  • $($example.Name)" -ForegroundColor Green
        Write-Host "    $($example.Description)" -ForegroundColor Gray
    }
    exit 0
}

# Filter examples based on ExampleName parameter
$ExamplesToTest = if ($ExampleName) {
    $IpamExamples | Where-Object { $_.Name -eq $ExampleName }
} else {
    $IpamExamples
}

# Color functions for output
function Write-Success($Message) { Write-Host $Message -ForegroundColor Green }
function Write-Error($Message) { Write-Host $Message -ForegroundColor Red }
function Write-Warning($Message) { Write-Host $Message -ForegroundColor Yellow }
function Write-Info($Message) { Write-Host $Message -ForegroundColor Cyan }

# Function to run terraform commands and capture output
function Test-TerraformExample {
    param(
        [string]$ExamplePath,
        [string]$ExampleName,
        [string]$Description,
        [bool]$SkipApply = $false,
        [bool]$ApplyOnly = $false,
        [bool]$DestroyOnly = $false,
        [bool]$ManualVerification = $false
    )

    Write-Info "=========================================="
    Write-Info "Testing: $ExampleName"
    Write-Info "Description: $Description"
    Write-Info "Path: $ExamplePath"
    if ($SkipApply) { Write-Info "Mode: VALIDATION ONLY" }
    elseif ($ApplyOnly) { Write-Info "Mode: APPLY ONLY" }
    elseif ($DestroyOnly) { Write-Info "Mode: DESTROY ONLY" }
    else { Write-Info "Mode: FULL END-TO-END" }
    Write-Info "=========================================="

    $result = @{
        Name = $ExampleName
        Description = $Description
        Path = $ExamplePath
        InitSuccess = $false
        ValidateSuccess = $false
        PlanSuccess = $false
        ApplySuccess = $false
        DestroySuccess = $false
        InitOutput = ""
        ValidateOutput = ""
        PlanOutput = ""
        ApplyOutput = ""
        DestroyOutput = ""
        InitError = ""
        ValidateError = ""
        PlanError = ""
        ApplyError = ""
        DestroyError = ""
        Duration = 0
        ApplyDuration = 0
        DestroyDuration = 0
        DestroyAttempts = 0
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $originalLocation = Get-Location

    try {
        Set-Location $ExamplePath

        # Skip init/validate/plan for DestroyOnly mode
        if (-not $DestroyOnly) {
            Write-Info "Step 1: Terraform Init..."
            try {
                $initOutput = terraform init 2>&1 | Out-String
                $result.InitOutput = $initOutput

                if ($LASTEXITCODE -eq 0) {
                    $result.InitSuccess = $true
                    Write-Success "✅ Init: SUCCESS"
                } else {
                    $result.InitError = $initOutput
                    Write-Error "❌ Init: FAILED"
                    Write-Error $initOutput
                    return $result
                }
            } catch {
                $result.InitError = $_.Exception.Message
                Write-Error "❌ Init: EXCEPTION - $($_.Exception.Message)"
                return $result
            }

            Write-Info "Step 2: Terraform Validate..."
            try {
                $validateOutput = terraform validate -no-color 2>&1 | Out-String
                $result.ValidateOutput = $validateOutput

                if ($LASTEXITCODE -eq 0) {
                    $result.ValidateSuccess = $true
                    Write-Success "✅ Validate: SUCCESS"
                } else {
                    $result.ValidateError = $validateOutput
                    Write-Error "❌ Validate: FAILED"
                    Write-Error $validateOutput
                    return $result
                }
            } catch {
                $result.ValidateError = $_.Exception.Message
                Write-Error "❌ Validate: EXCEPTION - $($_.Exception.Message)"
                return $result
            }

            Write-Info "Step 3: Terraform Plan..."
            try {
                # Run plan with detailed output
                $planOutput = terraform plan -detailed-exitcode -no-color 2>&1 | Out-String
                $result.PlanOutput = $planOutput

                if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 2) {
                    # Exit code 0 = no changes, 2 = changes found (both are success for plan)
                    $result.PlanSuccess = $true
                    Write-Success "✅ Plan: SUCCESS (Exit code: $LASTEXITCODE)"

                    if ($LASTEXITCODE -eq 2) {
                        Write-Info "📋 Plan shows resources will be created/modified"
                    } else {
                        Write-Info "📋 Plan shows no changes needed"
                    }
                } else {
                    $result.PlanError = $planOutput
                    Write-Error "❌ Plan: FAILED (Exit code: $LASTEXITCODE)"
                    Write-Error $planOutput
                    return $result
                }
            } catch {
                $result.PlanError = $_.Exception.Message
                Write-Error "❌ Plan: EXCEPTION - $($_.Exception.Message)"
                return $result
            }
        } else {
            # For DestroyOnly mode, mark these as successful
            $result.InitSuccess = $true
            $result.ValidateSuccess = $true
            $result.PlanSuccess = $true
        }

        # Apply phase (if not SkipApply and not DestroyOnly)
        if (-not $SkipApply -and -not $DestroyOnly) {
            Write-Info "Step 4: Terraform Apply..."
            $applyStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                # Auto-approve for automated testing
                $applyOutput = terraform apply -auto-approve -no-color 2>&1 | Out-String
                $result.ApplyOutput = $applyOutput
                $applyStopwatch.Stop()
                $result.ApplyDuration = $applyStopwatch.ElapsedMilliseconds

                if ($LASTEXITCODE -eq 0) {
                    $result.ApplySuccess = $true
                    Write-Success "✅ Apply: SUCCESS (Duration: $($result.ApplyDuration)ms)"
                    Write-Success "🏗️  Infrastructure deployed successfully!"

                    # Manual verification pause
                    if ($ManualVerification) {
                        Write-Warning "⏸️  MANUAL VERIFICATION MODE"
                        Write-Warning "🔍 Please verify the resources in Azure Portal"
                        Write-Warning "📍 Resource Group: Check the deployed resources"
                        Write-Warning "🌐 Virtual Network: Verify IPAM allocation worked correctly"
                        Write-Host ""
                        Read-Host "Press ENTER when ready to continue with destroy..."
                    }
                } else {
                    $result.ApplyError = $applyOutput
                    Write-Error "❌ Apply: FAILED (Duration: $($result.ApplyDuration)ms)"
                    Write-Error $applyOutput
                    return $result
                }
            } catch {
                $applyStopwatch.Stop()
                $result.ApplyDuration = $applyStopwatch.ElapsedMilliseconds
                $result.ApplyError = $_.Exception.Message
                Write-Error "❌ Apply: EXCEPTION (Duration: $($result.ApplyDuration)ms) - $($_.Exception.Message)"
                return $result
            }
        }

        # Destroy phase (if not SkipApply and not ApplyOnly)
        if (-not $SkipApply -and -not $ApplyOnly) {
            Write-Info "Step 5: Terraform Destroy..."
            $destroyStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Retry configuration for destroy operations
            $maxDestroyAttempts = $DestroyRetries
            $destroyAttempt = 1
            $destroySuccess = $false
            $allDestroyOutputs = @()

            while ($destroyAttempt -le $maxDestroyAttempts -and -not $destroySuccess) {
                try {
                    if ($destroyAttempt -gt 1) {
                        $waitTime = [Math]::Pow(2, $destroyAttempt - 1) * 30  # 30s, 60s, 120s, 240s...
                        Write-Warning "🔄 Destroy attempt $destroyAttempt of $maxDestroyAttempts (waiting ${waitTime}s for resources to settle...)"
                        Write-Info "⏳ Azure resources sometimes need time to process deletions and update dependencies"
                        Start-Sleep -Seconds $waitTime
                    } else {
                        Write-Info "🔄 Destroy attempt $destroyAttempt of $maxDestroyAttempts"
                    }

                    # Enhanced destroy command with longer timeout and parallelism control
                    $destroyOutput = terraform destroy -auto-approve -no-color -parallelism=1 2>&1 | Out-String
                    $allDestroyOutputs += "=== ATTEMPT $destroyAttempt ($(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) ===`n$destroyOutput`n"

                    if ($LASTEXITCODE -eq 0) {
                        $destroySuccess = $true
                        $result.DestroySuccess = $true
                        $result.DestroyAttempts = $destroyAttempt
                        $destroyStopwatch.Stop()
                        $result.DestroyDuration = $destroyStopwatch.ElapsedMilliseconds
                        $result.DestroyOutput = $allDestroyOutputs -join "`n"
                        Write-Success "✅ Destroy: SUCCESS on attempt $destroyAttempt (Duration: $($result.DestroyDuration)ms)"
                        Write-Success "💥 Infrastructure cleaned up successfully!"
                        break
                    } else {
                        # Check for specific error patterns that might benefit from retry
                        $retryableErrors = @(
                            "DependentResourceExists",
                            "ResourceGroupNotEmpty",
                            "NetworkSecurityGroupInUse",
                            "SubnetInUse",
                            "PublicIPAddressCannotBeDeleted",
                            "timeout"
                        )

                        $isRetryableError = $retryableErrors | Where-Object { $destroyOutput -match $_ }

                        if ($isRetryableError -and $destroyAttempt -lt $maxDestroyAttempts) {
                            Write-Warning "⚠️  Destroy attempt $destroyAttempt failed with potentially retryable error: $($isRetryableError -join ', ')"
                            Write-Info "🔄 Azure networking resources often have dependencies that need time to clear"
                        } else {
                            Write-Warning "⚠️  Destroy attempt $destroyAttempt failed (Exit code: $LASTEXITCODE)"
                        }

                        if ($destroyAttempt -eq $maxDestroyAttempts) {
                            # Final attempt failed
                            $result.DestroyAttempts = $destroyAttempt
                            $destroyStopwatch.Stop()
                            $result.DestroyDuration = $destroyStopwatch.ElapsedMilliseconds
                            $result.DestroyError = $allDestroyOutputs -join "`n"
                            Write-Error "❌ Destroy: FAILED after $maxDestroyAttempts attempts (Duration: $($result.DestroyDuration)ms)"
                            Write-Error "💡 Consider manually checking Azure Portal for resources that may need manual cleanup"
                            Write-Error "💡 You can also try running with more retries using -DestroyRetries parameter"
                            Write-Error "Full destroy output from all attempts:"
                            Write-Error ($allDestroyOutputs -join "`n")
                        }
                    }
                } catch {
                    Write-Warning "⚠️  Destroy attempt $destroyAttempt encountered exception: $($_.Exception.Message)"
                    $allDestroyOutputs += "=== ATTEMPT $destroyAttempt EXCEPTION ===`n$($_.Exception.Message)`n"

                    if ($destroyAttempt -eq $maxDestroyAttempts) {
                        # Final attempt failed
                        $result.DestroyAttempts = $destroyAttempt
                        $destroyStopwatch.Stop()
                        $result.DestroyDuration = $destroyStopwatch.ElapsedMilliseconds
                        $result.DestroyError = $allDestroyOutputs -join "`n"
                        Write-Error "❌ Destroy: EXCEPTION after $maxDestroyAttempts attempts (Duration: $($result.DestroyDuration)ms)"
                        Write-Error "Full destroy output from all attempts:"
                        Write-Error ($allDestroyOutputs -join "`n")
                    }
                }
                $destroyAttempt++
            }
        }

    } catch {
        Write-Error "❌ Unexpected error: $($_.Exception.Message)"
    } finally {
        # Always return to original location
        Set-Location $originalLocation
        $stopwatch.Stop()
        $result.Duration = $stopwatch.ElapsedMilliseconds

        # Display completion summary
        $durationText = "$($result.Duration)ms"
        Write-Info "🎉 Example '$ExampleName' testing completed in $durationText"
        Write-Info ""
    }

    return $result
}

# Function to generate summary report
function Write-TestSummary($TestResults, $StartTime, $SkipApply, $ApplyOnly, $DestroyOnly) {
    $endTime = Get-Date
    $totalDuration = ($endTime - $StartTime).TotalSeconds

    Write-Info "============================================"
    Write-Info "📊 IPAM EXAMPLES TEST REPORT"
    Write-Info "============================================"
    Write-Info "Total Runtime: $totalDuration seconds"
    Write-Info ""

    Write-Info "📋 SUMMARY TABLE:"
    Write-Host "Example Name        Init  Validate  Plan  Apply  Destroy  Duration" -ForegroundColor Yellow
    Write-Host "-" -ForegroundColor Yellow

    foreach ($result in $TestResults) {
        $initStatus = if ($result.InitSuccess -or $DestroyOnly) { "✅ PASS" } else { "❌ FAIL" }
        $validateStatus = if ($result.ValidateSuccess -or $DestroyOnly) { "✅ PASS" } else { "❌ FAIL" }
        $planStatus = if ($result.PlanSuccess -or $DestroyOnly) { "✅ PASS" } else { "❌ FAIL" }
        $applyStatus = if ($SkipApply -or $DestroyOnly) { "⏭️ SKIP" } elseif ($result.ApplySuccess) { "✅ PASS" } else { "❌ FAIL" }
        $destroyStatus = if ($SkipApply -or $ApplyOnly) { "⏭️ SKIP" } elseif ($result.DestroySuccess) { "✅ PASS" } else { "❌ FAIL" }

        Write-Host ("{0,-18} {1,-4} {2,-8} {3,-4} {4,-5} {5,-7} {6}" -f $result.Name, $initStatus, $validateStatus, $planStatus, $applyStatus, $destroyStatus, "$($result.Duration)ms") -ForegroundColor White
    }

    Write-Info ""
    Write-Info "📊 DETAILED RESULTS:"
    foreach ($result in $TestResults) {
        Write-Info "----------------------------------------"
        Write-Info "Example: $($result.Name)"
        Write-Info "Description: $($result.Description)"

        $allPassed = $true
        if (-not $DestroyOnly -and (-not $result.InitSuccess -or -not $result.ValidateSuccess -or -not $result.PlanSuccess)) { $allPassed = $false }
        if (-not $SkipApply -and -not $DestroyOnly -and -not $result.ApplySuccess) { $allPassed = $false }
        if (-not $SkipApply -and -not $ApplyOnly -and -not $result.DestroySuccess) { $allPassed = $false }

        if ($allPassed) {
            Write-Success "Status: ✅ ALL TESTS PASSED"
        } else {
            Write-Error "Status: ❌ SOME TESTS FAILED"
        }
    }

    Write-Info ""
    Write-Info "🎯 FINAL RESULTS:"
    $passedCount = 0
    $totalCount = $TestResults.Count

    foreach ($result in $TestResults) {
        $passed = $true
        if (-not $DestroyOnly -and (-not $result.InitSuccess -or -not $result.ValidateSuccess -or -not $result.PlanSuccess)) { $passed = $false }
        if (-not $SkipApply -and -not $DestroyOnly -and -not $result.ApplySuccess) { $passed = $false }
        if (-not $SkipApply -and -not $ApplyOnly -and -not $result.DestroySuccess) { $passed = $false }
        if ($passed) { $passedCount++ }
    }

    if ($passedCount -eq $totalCount) {
        Write-Success "🎉 ALL IPAM EXAMPLES PASSED! ($passedCount/$totalCount)"
        if ($SkipApply) {
            Write-Success "✅ All IPAM scenarios are syntactically correct"
            Write-Success "✅ Ready for deployment testing"
        } elseif ($ApplyOnly) {
            Write-Success "✅ All IPAM scenarios deployed successfully"
            Write-Success "⏭️  Use -DestroyOnly to clean up resources"
        } elseif ($DestroyOnly) {
            Write-Success "✅ All IPAM resources destroyed successfully"
        } else {
            Write-Success "✅ All IPAM scenarios work end-to-end"
            Write-Success "✅ Infrastructure deployed and cleaned up successfully"
        }
    } else {
        Write-Error "❌ SOME IPAM EXAMPLES FAILED ($passedCount/$totalCount passed)"
        Write-Warning "⚠️  Check the detailed results above for specific failures"
    }
}

# Generate timestamped report filename
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportFile = "ipam-test-report-$timestamp.json"

# Determine test mode and display header
$testMode = if ($SkipApply) { "VALIDATION ONLY" } elseif ($ApplyOnly) { "APPLY ONLY" } elseif ($DestroyOnly) { "DESTROY ONLY" } else { "FULL END-TO-END" }
$targetInfo = if ($ExampleName) { "SINGLE EXAMPLE: $ExampleName" } else { "ALL EXAMPLES" }

Write-Info "🚀 Starting IPAM Examples Test Suite ($testMode)"
if ($SkipApply) { Write-Info "⏭️  Apply and Destroy phases will be SKIPPED" }
elseif ($ApplyOnly) { Write-Info "🚀 Only Apply phase will be executed" }
elseif ($DestroyOnly) { Write-Info "💥 Only Destroy phase will be executed" }
else { Write-Info "🔄 Full deployment cycle will be executed" }

Write-Info "🎯 Target: $targetInfo"
Write-Info "Testing $(($ExamplesToTest | Measure-Object).Count) IPAM examples..."

# Safety confirmation for deployment modes
if (-not $SkipApply -and -not $DestroyOnly) {
    Write-Warning "⚠️  This will deploy real Azure resources and incur costs!"
    if (-not $ApplyOnly) {
        Write-Info "ℹ️  Resources will be automatically destroyed after testing."
    } else {
        Write-Warning "⚠️  Resources will NOT be destroyed (ApplyOnly mode)"
    }
    Write-Host ""
    $confirmation = Read-Host "Do you want to proceed? (yes/no)"
    if ($confirmation -notmatch "^(yes|y)$") {
        Write-Info "❌ Test cancelled by user"
        exit 0
    }
}

Write-Info ""
$startTime = Get-Date

# Test each example
foreach ($example in $ExamplesToTest) {
    $result = Test-TerraformExample -ExamplePath $example.Path -ExampleName $example.Name -Description $example.Description -SkipApply $SkipApply -ApplyOnly $ApplyOnly -DestroyOnly $DestroyOnly -ManualVerification $ManualVerification
    $TestResults += $result

    # Track overall success based on mode
    if ($SkipApply) {
        if (-not ($result.InitSuccess -and $result.ValidateSuccess -and $result.PlanSuccess)) {
            $OverallSuccess = $false
        }
    } elseif ($ApplyOnly) {
        if (-not ($result.InitSuccess -and $result.ValidateSuccess -and $result.PlanSuccess -and $result.ApplySuccess)) {
            $OverallSuccess = $false
        }
    } elseif ($DestroyOnly) {
        if (-not $result.DestroySuccess) {
            $OverallSuccess = $false
        }
    } else {
        if (-not ($result.InitSuccess -and $result.ValidateSuccess -and $result.PlanSuccess -and $result.ApplySuccess -and $result.DestroySuccess)) {
            $OverallSuccess = $false
        }
    }

    Start-Sleep -Seconds 2  # Brief pause between tests
}

# Generate and display test report
Write-TestSummary $TestResults $startTime $SkipApply $ApplyOnly $DestroyOnly

# Save detailed JSON report
Write-Info ""
Write-Info "📝 Test completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Info "📄 Detailed JSON report saved to: $reportFile"

$TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding UTF8

# Exit with appropriate code
exit $(if ($OverallSuccess) { 0 } else { 1 })

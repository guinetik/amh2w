#!/usr/bin/env pwsh
<#
.SYNOPSIS
Test script for the enhanced powerscan command with HWiNFO64 integration.

.DESCRIPTION
Tests the powerscan functionality with various scenarios.
#>

# Load the AMH2W module (adjust path as needed)
$scriptDir = Split-Path -Parent $PSScriptRoot
Import-Module "$scriptDir\AMH2W.psm1" -Force

Write-Host "=== AMH2W PowerScan Test Suite ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Basic powerscan
Write-Host "Test 1: Basic powerscan (table format, 0 second duration)" -ForegroundColor Yellow
try {
    $result = all my hardware powerscan table 0
    if ($result.ok) {
        Write-Host "✅ Test 1 PASSED: Basic powerscan completed successfully" -ForegroundColor Green
        Write-Host "   Message: $($result.message)" -ForegroundColor Gray
    } else {
        Write-Host "❌ Test 1 FAILED: $($result.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Test 1 ERROR: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: JSON format
Write-Host "Test 2: PowerScan with JSON format" -ForegroundColor Yellow
try {
    $result = all my hardware powerscan json 0
    if ($result.ok) {
        Write-Host "✅ Test 2 PASSED: JSON format output successful" -ForegroundColor Green
        
        # Verify the data structure
        $data = $result.value
        if ($data.ProcessorInfo -and $data.ThermalInfo) {
            Write-Host "   ✓ Data structure verified" -ForegroundColor Gray
            
            # Check for HWiNFO64 fields
            if ($data.ProcessorInfo[0].HWiNFOAvailable) {
                Write-Host "   ✓ HWiNFO64 integration fields present" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "❌ Test 2 FAILED: $($result.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Test 2 ERROR: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: Check HWiNFO64 detection
Write-Host "Test 3: HWiNFO64 detection test" -ForegroundColor Yellow
try {
    # Check if HWiNFO64 is available
    $hwinfo = Get-Command "HWiNFO64.exe" -ErrorAction SilentlyContinue
    if ($hwinfo) {
        Write-Host "✅ HWiNFO64 detected at: $($hwinfo.Source)" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  HWiNFO64 not installed - testing fallback behavior" -ForegroundColor Yellow
    }
    
    # Run powerscan to see if it handles HWiNFO64 properly
    $result = all my hardware powerscan table 0
    if ($result.ok) {
        Write-Host "✅ Test 3 PASSED: PowerScan handles HWiNFO64 status correctly" -ForegroundColor Green
    } else {
        Write-Host "❌ Test 3 FAILED: $($result.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Test 3 ERROR: $_" -ForegroundColor Red
}
Write-Host ""

# Test 4: Thermal data detection
Write-Host "Test 4: Thermal sensor detection" -ForegroundColor Yellow
try {
    $result = all my hardware powerscan json 0
    if ($result.ok -and $result.value.ThermalInfo) {
        $thermalInfo = $result.value.ThermalInfo
        Write-Host "✅ Test 4 PASSED: Thermal info retrieved" -ForegroundColor Green
        Write-Host "   Found $($thermalInfo.Count) thermal sensor(s)" -ForegroundColor Gray
        
        # Check if any have Source field
        $sourcedSensors = $thermalInfo | Where-Object { $_.Source }
        if ($sourcedSensors) {
            Write-Host "   ✓ Enhanced thermal data with source information present" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ Test 4 FAILED: No thermal info retrieved" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Test 4 ERROR: $_" -ForegroundColor Red
}
Write-Host ""

# Test 5: Power estimation
Write-Host "Test 5: CPU power estimation" -ForegroundColor Yellow
try {
    $result = all my hardware powerscan json 0
    if ($result.ok -and $result.value.ProcessorInfo) {
        $cpuInfo = $result.value.ProcessorInfo[0]
        if ($cpuInfo.EstimatedPower -and $cpuInfo.EstimatedTDP) {
            Write-Host "✅ Test 5 PASSED: CPU power estimation working" -ForegroundColor Green
            Write-Host "   CPU: $($cpuInfo.Name)" -ForegroundColor Gray
            Write-Host "   Estimated Power: $($cpuInfo.EstimatedPower)" -ForegroundColor Gray
            Write-Host "   TDP: $($cpuInfo.EstimatedTDP)" -ForegroundColor Gray
        } else {
            Write-Host "⚠️  Test 5 WARNING: Power estimation fields missing" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Test 5 FAILED: No processor info retrieved" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Test 5 ERROR: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== Test Suite Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Tips:" -ForegroundColor Yellow
Write-Host "   - Run as Administrator for full functionality" -ForegroundColor Gray
Write-Host "   - Install HWiNFO64 for enhanced thermal/power monitoring" -ForegroundColor Gray
Write-Host "   - Use 'all my hardware powerscan html' for detailed reports" -ForegroundColor Gray
function Bytes2String {
    param([int64]$Bytes)
    $units = "B","KB","MB","GB","TB","PB","EB"
    $i = 0
    while ($Bytes -gt 1024 -and $i -lt $units.Length - 1) {
        $Bytes /= 1024
        $i++
    }
    return "{0:N2} {1}" -f $Bytes, $units[$i]
}

function smart {
    try {
        # Check smartctl availability
        $smart = Get-Command smartctl -ErrorAction SilentlyContinue
        if (-not $smart) {
            return Err -Message "smartctl not found — please install smartmontools"
        }

        $scanCmd = if ($IsLinux) { "sudo smartctl --scan-open" } else { "smartctl --scan-open" }
        $devices = Invoke-Expression $scanCmd | Where-Object { $_ -notmatch '^#' }

        if (-not $devices) {
            return Err -Message "No SMART-capable devices found"
        }

        $results = @()
        foreach ($line in $devices) {
            $dev = ($line -split '\s+')[0]
            $cmdPrefix = if ($IsLinux) { "sudo" } else { "" }
            $json = & $cmdPrefix smartctl --all --json $dev | ConvertFrom-Json
            & $cmdPrefix smartctl --test=conveyance $dev | Out-Null

            $status = "✅"
            $model  = $json.model_name
            $proto  = $json.device.protocol
            $fw     = $json.firmware_version
            $temp   = $json.temperature.current
            $powerOnHrs = $json.power_on_time.hours
            $powerCycles = $json.power_cycle_count
            $smartPassed = $json.smart_status.passed
            $capacityBytes = $json.user_capacity.bytes

            $read = $json.nvme_smart_health_information_log.data_units_read
            $written = $json.nvme_smart_health_information_log.data_units_written

            $issues = @()
            if ($temp -gt 50) { $issues += "$temp°C TOO HOT"; $status = "⚠️" }
            elseif ($temp -lt 0) { $issues += "$temp°C TOO COLD"; $status = "⚠️" }
            else { $issues += "$temp°C" }

            if ($powerOnHrs -gt 87600) { $issues += "$powerOnHrs h (!)" ; $status = "⚠️" } else { $issues += "$powerOnHrs h" }
            if ($powerCycles -gt 100000) { $issues += "$powerCycles cycles (!)" ; $status = "⚠️" } else { $issues += "$powerCycles cycles" }

            if ($read)    { $issues += "$(Bytes2String ($read * 512 * 1000)) read" }
            if ($written) { $issues += "$(Bytes2String ($written * 512 * 1000)) written" }

            $issues += "v$fw"
            if ($smartPassed) { $issues += "test passed" } else { $issues += "test FAILED"; $status = "⚠️" }

            $output = "$status $(Bytes2String $capacityBytes) $model via $proto ($($issues -join ", "))"
            Write-Host $output -ForegroundColor (if ($status -eq "✅") { "Green" } else { "Yellow" })

            $results += [PSCustomObject]@{
                Device       = $dev
                Model        = $model
                Protocol     = $proto
                Capacity     = Bytes2String $capacityBytes
                Firmware     = $fw
                Temperature  = $temp
                PowerOnHours = $powerOnHrs
                PowerCycles  = $powerCycles
                SmartPassed  = $smartPassed
                Status       = $status
                Details      = ($issues -join ", ")
            }
        }

        return Ok -Value $results -Message "SMART data parsed for $($results.Count) device(s)"
    }
    catch {
        Write-Host "Error: Command function '$arg' failed: $_" -ForegroundColor Red
        return Err -Message "Error gathering storage health: $_"
    }
}

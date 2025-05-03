function GetCPUArchitecture {
    if ($env:PROCESSOR_ARCHITECTURE) {
        return $env:PROCESSOR_ARCHITECTURE
    }

    if ($IsLinux) {
        $uname = (uname -m 2>$null)
        switch -Regex ($uname) {
            "armv7" { return "ARM32" }
            "aarch64" { return "ARM64" }
            "x86_64" { return "x64" }
            "i386|i686" { return "x86" }
            default { return $uname }
        }
    }

    return "Unknown"
}

function GetCPUTemperature {
    try {
        if ($IsLinux) {
            $path = "/sys/class/thermal/thermal_zone0/temp"
            if (Test-Path $path) {
                $intTemp = Get-Content $path
                return [math]::Round($intTemp / 1000.0, 1)
            }
        }
        else {
            $class = "Win32_PerfFormattedData_Counters_ThermalZoneInformation"
            $namespace = "root/CIMV2"

            $thermal = Get-WmiObject -Namespace $namespace -Query "SELECT * FROM $class" -ErrorAction Stop
            foreach ($item in $thermal) {
                if ($item.HighPrecisionTemperature) {
                    return [math]::Round($item.HighPrecisionTemperature / 100.0, 1)
                }
            }
        }
    } catch {
        Log-Warning "Could not retrieve temperature: $_"
    }

    return $null
}

function cpu {
    try {
        Write-Progress "Querying CPU status..."

        $arch = GetCPUArchitecture
        $cores = [Environment]::ProcessorCount
        $temp = GetCPUTemperature

        if ($IsLinux) {
            $cpuName = (lscpu | Select-String "Model name" | ForEach-Object { $_ -replace "Model name:\s+", "" }).Trim()
            $deviceID = ""
            $speed = ""
            $socket = ""
        }
        else {
            $cpuInfo = Get-WmiObject -Class Win32_Processor
            $cpuName = $cpuInfo.Name.Trim()
            $deviceID = $cpuInfo.DeviceID
            $speed = "$($cpuInfo.MaxClockSpeed) MHz"
            $socket = $cpuInfo.SocketDesignation
        }

        # Temperature status
        $tempLabel = ""
        $status = "✅"

        if ($temp -ne $null) {
            if ($temp -gt 80) { $tempLabel = "$temp°C TOO HOT"; $status = "🔥" }
            elseif ($temp -gt 50) { $tempLabel = "$temp°C HOT"; $status = "⚠️" }
            elseif ($temp -lt 0) { $tempLabel = "$temp°C TOO COLD"; $status = "🥶" }
            else { $tempLabel = "$temp°C" }
        }

        Write-Progress "Done" -Completed

        # Output section
        Write-Host "`n🧠 CPU Information:" -ForegroundColor Cyan
        Write-Host "-------------------" -ForegroundColor Cyan
        Write-Host "Name        : $cpuName"
        Write-Host "Architecture: $arch"
        Write-Host "Cores       : $cores"
        if ($speed)     { Write-Host "Speed       : $speed" }
        if ($socket)    { Write-Host "Socket      : $socket" }
        if ($deviceID)  { Write-Host "Device ID   : $deviceID" }
        if ($tempLabel) { Write-Host "Temperature : $tempLabel" -ForegroundColor Yellow }

        $cpuObject = [PSCustomObject]@{
            Name        = $cpuName
            Architecture= $arch
            Cores       = $cores
            Speed       = $speed
            Socket      = $socket
            DeviceID    = $deviceID
            Temperature = $temp
            Status      = $status
        }

        return Ok -Value $cpuObject
    }
    catch {
        return Err -Msg "CPU query failed: $_"
    }
}

# all/my/uptime.ps1
param(
    [Parameter(Position = 0)]
    [string]$Format,
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)
$ErrorActionPreference = 'Stop'

function uptime() {
    $Context = New-PipelineContext
    # Main execution
    Log info "Getting system uptime..." $Context
    $result = Invoke-Pipeline -Steps @(
        {
            try {
                $uptimeData = Get-SystemUptime
                return Ok $uptimeData
            }
            catch {
                return Err "Failed to retrieve system uptime: $_"
            }
        }
    ) -Context $Context

    # The error was here - we need to check if result is a boolean, not try to unwrap it
    if ($result) {
        # Get the uptime data directly from the last step execution
        $uptimeData = Get-SystemUptime
        Show-UptimeInfo -UptimeData $uptimeData -Format $Format
    }
    # Return result for pipeline
    return Ok "Uptime command executed successfully"
}

function Get-SystemUptime {
    $lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $lastBootTime
    return @{
        LastBoot     = $lastBootTime
        Days         = $uptime.Days
        Hours        = $uptime.Hours
        Minutes      = $uptime.Minutes
        Seconds      = $uptime.Seconds
        TotalHours   = [math]::Round($uptime.TotalHours, 2)
        TotalMinutes = [math]::Round($uptime.TotalMinutes, 2)
        TotalSeconds = [math]::Round($uptime.TotalSeconds, 2)
    }
}

function Format-Uptime {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$UptimeData,
    
        [Parameter(Mandatory = $true)]
        [string]$Format
    )

    switch ($Format.ToLower()) {
        "default" {
            $formattedUptime = "$($UptimeData.Days) days, $($UptimeData.Hours) hours, $($UptimeData.Minutes) minutes"
            return $formattedUptime
        }
        "short" {
            return "$($UptimeData.Days)d $($UptimeData.Hours)h $($UptimeData.Minutes)m"
        }
        "minimal" {
            if ($UptimeData.Days -gt 0) {
                return "$($UptimeData.Days)d"
            }
            elseif ($UptimeData.Hours -gt 0) {
                return "$($UptimeData.Hours)h"
            }
            else {
                return "$($UptimeData.Minutes)m"
            }
        }
        "hours" {
            return "$($UptimeData.TotalHours) hours"
        }
        "minutes" {
            return "$($UptimeData.TotalMinutes) minutes"
        }
        "seconds" {
            return "$($UptimeData.TotalSeconds) seconds"
        }
        "full" {
            $bootTime = $UptimeData.LastBoot.ToString("yyyy-MM-dd HH:mm:ss")
            $formattedUptime = "$($UptimeData.Days) days, $($UptimeData.Hours) hours, $($UptimeData.Minutes) minutes, $($UptimeData.Seconds) seconds"
            return "System boot time: $bootTime`nUptime: $formattedUptime"
        }
        "json" {
            return $UptimeData | ConvertTo-Json
        }
        default {
            return "$($UptimeData.Days) days, $($UptimeData.Hours) hours, $($UptimeData.Minutes) minutes"
        }
    }
}

function Show-UptimeInfo {
    param(
        [hashtable]$UptimeData,
        [string]$Format
    )

    $formattedUptime = Format-Uptime -UptimeData $UptimeData -Format $Format

    if ($Format -eq "json") {
        Write-Output $formattedUptime
    }
    else {
        Write-Host "System Uptime: " -ForegroundColor Cyan -NoNewline
        Write-Host $formattedUptime -ForegroundColor White
    }
}

if ($Format) {
    uptime
}

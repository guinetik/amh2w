# all/my/uptime.ps1
# Displays system uptime in various formats

function uptime {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Format = "default",
        
        [Parameter()]
        [bool]$Print = $true,
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    try {
        Log-Info "Getting system uptime information..."
        
        # Get system uptime data
        $uptimeData = Get-SystemUptime
        
        if ($null -eq $uptimeData) {
            Log-Error "Failed to retrieve system uptime"
            return Err "Failed to retrieve system uptime"
        }
        
        # Get formatted uptime
        $formattedOutput = Format-Uptime -UptimeData $uptimeData -Format $Format
        
        # Display uptime info if Print is true
        if ($Print) {
            Show-UptimeInfo -FormattedOutput $formattedOutput -UptimeData $uptimeData -Format $Format
        }
        
        # Return success with the uptime data
        return Ok -Value @{
            RawData = $uptimeData
            FormattedOutput = $formattedOutput
        } -Message "Uptime retrieved successfully"
    }
    catch {
        Log-Error "Error getting system uptime: $_"
        return Err "Error getting system uptime: $_"
    }
}

function Get-SystemUptime {
    try {
        Log-Debug "Retrieving last boot time from system"
        $lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        $uptime = (Get-Date) - $lastBootTime
        
        Log-Debug "Successfully retrieved system uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
        
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
    catch {
        Log-Error "Failed to retrieve system uptime: $_"
        return $null
    }
}

function Format-Uptime {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$UptimeData,
    
        [Parameter(Mandatory = $true)]
        [string]$Format
    )

    Log-Debug "Formatting uptime data using format: $Format"

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
            # Make sure we return a proper JSON string 
            return $UptimeData | ConvertTo-Json -Depth 3
        }
        default {
            Log-Warning "Unknown format '$Format', using default format"
            return "$($UptimeData.Days) days, $($UptimeData.Hours) hours, $($UptimeData.Minutes) minutes"
        }
    }
}

function Show-UptimeInfo {
    param(
        [string]$FormattedOutput,
        [hashtable]$UptimeData,
        [string]$Format
    )

    if ($Format.ToLower() -eq "json") {
        Log-Debug "Outputting uptime in JSON format"
        # Write the JSON to console
        Write-Host $FormattedOutput
    }
    else {
        Log-Debug "Displaying formatted uptime"
        Write-Host "System Uptime: " -ForegroundColor Cyan -NoNewline
        Write-Host $FormattedOutput -ForegroundColor White
    }
}

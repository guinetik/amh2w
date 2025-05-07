<#
.SYNOPSIS
Displays system uptime information in various formats.

.DESCRIPTION
RetrieveS and displays the current system uptime in multiple formats with color highlighting.
Supports various output formats including default, short, minimal, hours, minutes, seconds,
full (with boot time), and JSON.

.NOTES
File: all/my/uptime.ps1
Command: all my uptime [format]

.EXAMPLE
all my uptime
Displays system uptime in the default format (e.g., "5 days, 2 hours, 10 minutes").

.EXAMPLE
all my uptime short
Displays uptime in a compact format (e.g., "5d 2h 10m").

.EXAMPLE
all my uptime full
Displays detailed uptime information including the system boot time.

.EXAMPLE
all my uptime json
Outputs uptime information as a JSON object.

.OUTPUTS
Returns an Ok result object containing both raw uptime data and formatted output.
#>

<#
.SYNOPSIS
RetrieveS and displays system uptime information.

.DESCRIPTION
Gathers system uptime data and presents it in the specified format.
Supports multiple output formats and can either display the information
or return it silently.

.PARAMETER Format
Specifies the output format. Valid values are:
- default: "5 days, 2 hours, 10 minutes"
- short: "5d 2h 10m"
- minimal: Most significant unit only (e.g., "5d")
- hours: Total uptime in hours
- minutes: Total uptime in minutes
- seconds: Total uptime in seconds
- full: Complete details including boot time
- json: JSON formatted output

.PARAMETER Print
Indicates whether to display the output to console. Default is $true.

.PARAMETER Arguments
Additional arguments (currently unused).

.OUTPUTS
Returns an Ok result object containing both raw uptime data and formatted output,
or an Err result object if retrieval fails.

.EXAMPLE
uptime

.EXAMPLE
uptime -Format "short" -Print $false
#>
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

<#
.SYNOPSIS
Retrieves raw system uptime information.

.DESCRIPTION
Gathers the system's last boot time and calculates the current uptime in various units.

.OUTPUTS
A hashtable containing the following uptime information:
- LastBoot: The date and time of the last system boot
- Days: Number of days since boot
- Hours: Hours component of uptime
- Minutes: Minutes component of uptime
- Seconds: Seconds component of uptime
- TotalHours: Total uptime in hours
- TotalMinutes: Total uptime in minutes
- TotalSeconds: Total uptime in seconds

Returns $null if retrieval fails.

.NOTES
Uses CIM to retrieve the system's LastBootUpTime.
#>
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

<#
.SYNOPSIS
Formats uptime data according to the specified format.

.DESCRIPTION
Converts raw uptime data into a formatted string based on the requested format.

.PARAMETER UptimeData
A hashtable containing raw uptime information from Get-SystemUptime.

.PARAMETER Format
The desired output format. Supported formats are:
- default: "5 days, 2 hours, 10 minutes"
- short: "5d 2h 10m"
- minimal: Most significant unit only (e.g., "5d")
- hours: Total uptime in hours
- minutes: Total uptime in minutes
- seconds: Total uptime in seconds
- full: Complete details including boot time
- json: JSON formatted output

.OUTPUTS
A string representation of the uptime in the requested format.
#>
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

<#
.SYNOPSIS
Displays formatted uptime information to the console.

.DESCRIPTION
Outputs uptime information to the console with appropriate formatting and coloring.

.PARAMETER FormattedOutput
The pre-formatted uptime string to display.

.PARAMETER UptimeData
The raw uptime data (used for additional context if needed).

.PARAMETER Format
The format that was used to generate the formatted output.

.NOTES
Uses color highlighting for better readability. JSON format is output as-is without additional formatting.
#>
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

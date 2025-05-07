function Time-Check {
    param(
        [string]$TimeServer = "time.windows.com"
    )
    
    try {
        Log-Info "Checking time from $TimeServer..."
        $ntpResult = Get-NtpTime $TimeServer
        
        if ($ntpResult.ok) {
            Log-Info "NTP time from $TimeServer`: $($ntpResult.message)"
            return Ok $ntpResult.message -Message $ntpResult.message
        } else {
            Log-Error "Failed to get NTP time: $($ntpResult.message)"
            return Err "Failed to get NTP time: $($ntpResult.message)"
        }
    } catch {
        $errorMessage = $_.Exception.Message
        Log-Error "Failed to check NTP time: $errorMessage"
        return Err "Failed to check NTP time: $errorMessage"
    }
}

function Time-Set {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DateString
    )
    
    if (-not (Test-IsAdmin)) {
        $cmd = "all time set '$DateString'"
        Invoke-Elevate -Command $cmd $true "Setting the clock requires administrator privileges"
        return Ok $true -Message "Elevation requested."
    }
    
    try {
        # Try to parse the date string
        $newDateTime = [DateTime]::Parse($DateString)
        Log-Info "Setting system time to $newDateTime..."
        Set-Date $newDateTime
        
        Log-Info "Time set successfully to $newDateTime"
        return Ok $newDateTime -Message "Windows Time set to $newDateTime"
    } catch {
        $errorMessage = $_.Exception.Message
        Log-Error "Failed to set system time: $errorMessage"
        return Err "Failed to set system time: $errorMessage"
    }
}

function Time-Sync {
    param(
        [string]$TimeServer = "time.windows.com"
    )
    
    if (-not (Test-IsAdmin)) {
        $cmd = "all time sync '$TimeServer'"
        Invoke-Elevate -Command $cmd $true "Synchronizing the clock requires administrator privileges"
        return Ok $true -Message "Elevation requested."
    }
    
    try {
        Log-Info "Retrieving time from $TimeServer..."
        $ntpResult = Get-NtpTime $TimeServer
        
        if ($ntpResult.ok) {
            # Extract the datetime from the message
            $newDateTime = [DateTime]::Parse($ntpResult.message)
            
            # Set the system date and time
            Log-Info "Setting system time to $newDateTime..."
            Set-Date $newDateTime
            
            # Also configure Windows Time service to maintain synchronization
            Log-Info "Configuring Windows Time service for future synchronization..."
            
            # Enable Windows Time service and set it to automatic
            Set-Service -Name W32Time -StartupType Automatic
            Start-Service -Name W32Time
            
            # Set specified time server as the time source
            w32tm /config /manualpeerlist:"$TimeServer" /syncfromflags:manual /update
            
            # Restart the service to apply changes
            Restart-Service W32Time
            
            Log-Info "Time synchronized successfully. Current time: $newDateTime"
            return Ok $newDateTime -Message "Windows Time Updated to $newDateTime"
        } else {
            Log-Error "Failed to get NTP time: $($ntpResult.message)"
            return Err "Failed to get NTP time: $($ntpResult.message)"
        }
    } catch {
        $errorMessage = $_.Exception.Message
        Log-Error "Failed to update Windows time: $errorMessage"
        return Err "Failed to update system time: $errorMessage"
    }
}

function Time-Now {
    param(
        [Parameter(Position = 0)]
        [string]$Location = "Local"
    )
    
    # If no location specified or "local" is specified, just return local time
    if ($Location -eq "Local" -or [string]::IsNullOrWhiteSpace($Location)) {
        $currentTime = Get-Date
        Log-Info "Displaying local system time"
        return Ok $currentTime "Current local time: $currentTime"
    }
    
    # Check if it's a standard time zone ID
    try {   
        $allTimeZones = [System.TimeZoneInfo]::GetSystemTimeZones()
        $matchedTimeZone = $allTimeZones | Where-Object { $_.Id -eq $Location -or $_.DisplayName -like "*$Location*" } | Select-Object -First 1
        
        if ($matchedTimeZone) {
            $targetTime = [System.TimeZoneInfo]::ConvertTime((Get-Date), $matchedTimeZone)
            Log-Info "Found time zone: $($matchedTimeZone.Id)"
            return Ok $targetTime "Current time in $($matchedTimeZone.DisplayName) $targetTime"
        }
    }
    catch {
        Log-Warning "Error checking system time zones: $_"
    }
    
    # Check if it's a UTC/GMT offset format
    $utcGmtRegex = '^(UTC|GMT)([+-])(\d{1,2})(?::?(\d{2}))?$'
    if ($Location -match $utcGmtRegex) {
        $prefix = $Matches[1]
        $sign = $Matches[2]
        $hours = [int]$Matches[3]
        $minutes = if ($Matches[4]) { [int]$Matches[4] } else { 0 }
        
        $offset = if ($sign -eq '+') { $hours } else { -$hours }
        
        try {
            $utcTime = [System.DateTime]::UtcNow
            $targetTime = $utcTime.AddHours($offset).AddMinutes($(if ($sign -eq '+') { $minutes } else { -$minutes }))
            Log-Info "Calculated time using offset: $Location"
            return Ok $targetTime "Current time in $Location - $targetTime"
        }
        catch {
            Log-Warning "Error calculating time with offset: $_"
        }
    }
    
    # If we reach here, try using the geonames API to look up by location name
    Log-Info "Attempting to resolve location name: $Location"
    
    # Step 1: Get coordinates for the location
    #
    #$geocodeQuery = "http://api.geonames.org/geoCodeAddressJSON?q=$([System.Web.HttpUtility]::UrlEncode($Location))&username=$geonamesUsername"
    #
    #
    $geonamesUsername = "guinetik"
    $apiKey = "2bc1fc53d33743249f4c90309166bc83" #yolo
    $geocodeQuery = "https://api.geoapify.com/v1/geocode/search?text=$([System.Web.HttpUtility]::UrlEncode($Location))&lang=en&limit=1&type=locality&apiKey=$apiKey"
    $geocodeResult = fetch $geocodeQuery -NoPrint
    
    if (-not $geocodeResult.ok) {
        Log-Error "Failed to get location coordinates: $($geocodeResult.message)"
        return Err "Could not find coordinates for location: $Location"
    }
    
    # Parse the geocode response
    try {
        $geocodeData = $geocodeResult.value.ContentObject
        #A valid response should contain a features array with 1 result
        if (-not $geocodeData.features -or $geocodeData.features.Count -ne 1) {
            Log-Warning "No address data found for location: $Location"
            all my homies hate json $($geocodeData.features | ConvertTo-Json)
            return Err "Could not find location: $Location"
        }
        #Get the first feature
        $feature = $geocodeData.features[0]
        $latitude = $feature.properties.lat
        $longitude = $feature.properties.lon
        
        if (-not $latitude -or -not $longitude) {
            Log-Warning "No coordinates found for location: $Location"
            return Err "Could not find coordinates for location: $Location"
        }
        Log-Info "Found coordinates for $Location`: Lat $latitude, Lon $longitude"
        # This service is supposed to have a features[n].properties.timezone field, if so, we dont need to do the next step.
        # check here
        <# if ($feature.properties.timezone) {
            Log-Info "Timezone found for $Location`: $($feature.properties.timezone.name)"
            #Api returns timezone but not the local time :(
        } #>

        #
        # Step 2: Get timezone for these coordinates
        $timezoneQuery = "http://api.geonames.org/timezoneJSON?lat=$latitude&lng=$longitude&username=$geonamesUsername"
        $timezoneResult = fetch $timezoneQuery -NoPrint
        
        if (-not $timezoneResult.ok) {
            Log-Error "Failed to get timezone: $($timezoneResult.message)"
            return Err "Could not determine timezone for location: $Location"
        }
        
        # Parse the timezone response
        $timezoneData = $timezoneResult.value.ContentObject
        
        if (-not $timezoneData.timezoneId) {
            Log-Warning "No timezone data found for coordinates"
            return Err "Could not determine timezone for coordinates"
        }
        
        # Return the time from the API response
        $locationTime = if ($timezoneData.time) { 
            [DateTime]::Parse($timezoneData.time) 
        } else {
            # Calculate based on GMT offset if time not provided
            $gmtOffset = $timezoneData.gmtOffset
            [System.DateTime]::UtcNow.AddHours($gmtOffset)
        }
        
        return Ok $locationTime "Current time in $($timezoneData.timezoneId) ($Location): $locationTime"
    }
    catch {
        Log-Error "Error processing location data: $_"
        return Err "Failed to process location data for: $Location"
    }
}

function time {
    param(
        [Parameter(Position = 0)]
        [string]$Action = 'sync',
        
        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [string[]]$RemainingArgs
    )
    
    # Handle default arguments
    if ($null -eq $RemainingArgs) {
        $RemainingArgs = @()
    }
    
    # For commands that need a time server, ensure there's a default
    if ($Action -eq 'check' -or $Action -eq 'sync') {
        if ($RemainingArgs.Count -eq 0) {
            $RemainingArgs = @("time.windows.com")
        }
    }
    
    # Command mapping table - makes it easy to add new commands
    $commands = @{
        'check' = {
            param($argz)
            Time-Check -TimeServer $argz[0]
        }
        
        'set' = {
            param($argz)
            if ($argz.Count -eq 0) {
                return Err "No date specified for 'set' action. Please provide a date string."
            }
            Time-Set -DateString $argz[0]
        }
        
        'sync' = {
            param($argz)
            Time-Sync -TimeServer $argz[0]
        }

        'now' = {
            param($argz)
            # If no location provided, use local time
            if ($argz.Count -eq 0) {
                Time-Now
            } else {
                # Join remaining args in case location has spaces
                $locationString = $argz -join " "
                Time-Now -Location $locationString
            }
        }
    }
    
    # Check if the requested action exists
    if (-not $commands.ContainsKey($Action)) {
        $validCommands = $commands.Keys -join ", "
        Write-Host "Unknown action: $Action."
        Write-Host "Valid actions are: $validCommands"
        return Ok "Unknown action: $Action."
    }
    
    # Execute the appropriate command
    & $commands[$Action] $RemainingArgs
}

Function Get-NtpTime ( [String]$NTPServer ) {
    # Build NTP request packet. We'll reuse this variable for the response packet
    $NTPData = New-Object byte[] 48  # Array of 48 bytes set to zero
    $NTPData[0] = 27                    # Request header: 00 = No Leap Warning; 011 = Version 3; 011 = Client Mode; 00011011 = 27

    # Open a connection to the NTP service
    $Socket = New-Object Net.Sockets.Socket ( 'InterNetwork', 'Dgram', 'Udp' )
    $Socket.SendTimeOut = 2000  # ms
    $Socket.ReceiveTimeOut = 2000  # ms
    $Socket.Connect( $NTPServer, 123 )

    # Make the request
    $Null = $Socket.Send(    $NTPData )
    $Null = $Socket.Receive( $NTPData )

    # Clean up the connection
    $Socket.Shutdown( 'Both' )
    $Socket.Close()

    # Extract relevant portion of first date in result (Number of seconds since "Start of Epoch")
    $Seconds = [BitConverter]::ToUInt32( $NTPData[43..40], 0 )

    # Add them to the "Start of Epoch", convert to local time zone, and return
    $resultFormatted = ( [datetime]'1/1/1900' ).AddSeconds( $Seconds ).ToLocalTime()
    return Ok $NTPData[43..40] $resultFormatted 
}
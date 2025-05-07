# Cache file path for ISS position
$script:ISSCachePath = Join-Path $PSScriptRoot "iss_position_cache.json"

function iss {
    param(
        [string]$Command = "help",
        [switch]$Track,
        [int]$UpdateInterval = 5,
        [string]$Location
    )

    if (-not $Location) {
        # Get user's location from IP if not provided
        $loc = all my location
        if ($loc.ok) {
            $Location = $loc.value
        } else {
            return Err "Could not determine location. Please provide a location object"
        }
    } else {
        # Parse string location into custom object
        $coords = $Location -split ','
        if ($coords.Count -ne 2) {
            return Err "Invalid location format. Use: latitude,longitude"
        }
        $Location = [PSCustomObject]@{
            lat = [double]$coords[0].Trim()
            lon = [double]$coords[1].Trim()
            City = "Unknown"
            Country = "Unknown"
        }
    }

    Log-Info "Location Resolved: $Location"

    Show-ISSArt

    try {
        switch ($Command) {
            "position" {
                return Get-ISSPosition
            }
            "track" {
                Write-Host "Track command received $Location"
                return Invoke-Track-ISS -UpdateInterval $UpdateInterval -UserLocation $Location
            }
            "crew" {
                return Get-ISSCrew
            }
            "pass" {
                return Get-ISSPasses -Location $Location
            }
            "map" {
                return Show-ISSMap
            }
            default {
                return Show-ISSHelp
            }
        }
    }
    catch {
        Log-Error "ISS command error: $_"
        return Err "Failed to execute ISS command: $_"
    }
}

function Get-ISSPosition {
    try {
        Write-Host "📡 Getting ISS position..." -ForegroundColor Cyan
        
        # Try to get cached position first
        $cachedPosition = $null
        if (Test-Path $script:ISSCachePath) {
            try {
                $cachedPosition = Get-Content $script:ISSCachePath | ConvertFrom-Json
                Write-Host "Found cached position from: $($cachedPosition.timestamp)" -ForegroundColor DarkGray
            } catch {
                Write-Host "Failed to read cache file" -ForegroundColor DarkGray
            }
        }

        # Try to get fresh position
        try {
            $response = Invoke-WebRequest "http://api.open-notify.org/iss-now.json" -userAgent "curl" -useBasicParsing
            $ISS = $response.Content | ConvertFrom-Json
            
            # Add timestamp to the data
            $ISS | Add-Member -NotePropertyName "timestamp" -NotePropertyValue (Get-Date -Format "o") -Force
            
            # Update cache
            $ISS | ConvertTo-Json | Set-Content $script:ISSCachePath
            
            Write-Host "Successfully updated position cache" -ForegroundColor DarkGray
        } catch {
            Write-Host "Failed to get fresh position, using cached data" -ForegroundColor Yellow
            if ($cachedPosition) {
                $ISS = $cachedPosition
            } else {
                throw "No cached position available and API request failed"
            }
        }
    
        # Get location name using reverse geocoding
        $locationName = "Over the ocean"
        try {
            $geocodeUrl = "https://nominatim.openstreetmap.org/reverse?format=json&lat=$($ISS.iss_position.latitude)&lon=$($ISS.iss_position.longitude)"
            $locationResponse = Invoke-WebRequest $geocodeUrl -userAgent "AMH2W/1.0" -useBasicParsing
            $locationData = $locationResponse.Content | ConvertFrom-Json
            if ($locationData.address.country) {
                $locationName = "Over $($locationData.address.country)"
                if ($locationData.address.state) {
                    $locationName += ", $($locationData.address.state)"
                }
            }
        } catch {
            # Fallback to basic location name
        }
        
        Write-Host ""
        Write-Host "🛰️ International Space Station Current Position" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host "📍 Latitude:  " -NoNewline -ForegroundColor Yellow
        Write-Host "$($ISS.iss_position.latitude)°" -ForegroundColor White
        Write-Host "📍 Longitude: " -NoNewline -ForegroundColor Yellow
        Write-Host "$($ISS.iss_position.longitude)°" -ForegroundColor White
        Write-Host "🌍 Location:  " -NoNewline -ForegroundColor Yellow
        Write-Host $locationName -ForegroundColor White
        Write-Host "⚡ Speed:     " -NoNewline -ForegroundColor Yellow
        Write-Host "~27,600 km/h (7.66 km/s)" -ForegroundColor White
        Write-Host "🔄 Orbit:     " -NoNewline -ForegroundColor Yellow
        Write-Host "~408 km above Earth" -ForegroundColor White
        Write-Host ""
        
        return Ok -Value $ISS -Message "ISS position retrieved"
    }
    catch {
        Log-Error "Failed to get ISS position: $_"
        return Err "Failed to get ISS position"
    }
}

function Invoke-Track-ISS {
    param(
        [int]$UpdateInterval = 5,
        [PSCustomObject]$UserLocation
    )
    Log-Info "CustomUserLocation: $($UserLocation.LatitudeDouble), $($UserLocation.LongitudeDouble)"
    Write-Host "`n🚀 Starting real-time ISS tracking..." -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop tracking`n" -ForegroundColor Yellow
    
    $tracking = $true
    $positions = @()
    
    try {
        while ($tracking) {
            $result = Get-ISSPosition
            if ($result.ok) {
                $positions += $result.Value
                
                # Show simple ASCII map
                $ISSLocation = [PSCustomObject]@{
                    lat = $result.Value.iss_position.latitude
                    lon = $result.Value.iss_position.longitude
                }
                Show-ISSWorldMap -ISSLocation $ISSLocation -UserLocation $UserLocation
                
                # Show tracking info
                Write-Host "Tracking for: " -NoNewline -ForegroundColor Yellow
                Write-Host "$($positions.Count * $UpdateInterval) seconds" -ForegroundColor White
                Write-Host "Next update in $UpdateInterval seconds..." -ForegroundColor DarkGray
            }
            
            Start-Sleep -Seconds $UpdateInterval
        }
    }
    catch {
        Write-Host "`nTracking stopped." -ForegroundColor Yellow
        Write-Host "Error: $_" -ForegroundColor Red
        Log-Error "Invoke-Track-ISS error: $_"
    }
    
    return Ok -Value $positions -Message "Tracked $($positions.Count) positions"
}

function Get-ISSCrew {
    try {
        $response = Invoke-WebRequest "http://api.open-notify.org/astros.json" -userAgent "curl" -useBasicParsing
        $crew = $response.Content | ConvertFrom-Json
        
        $issAstronauts = $crew.people | Where-Object { $_.craft -eq "ISS" }
        
        Write-Host ""
        Write-Host "👨‍🚀 Current ISS Crew ($($issAstronauts.Count) astronauts)" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        
        foreach ($astronaut in $issAstronauts) {
            Write-Host "• $($astronaut.name)" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "Total people in space: $($crew.number)" -ForegroundColor Yellow
        Write-Host ""
        
        return Ok -Value $crew -Message "ISS crew information retrieved"
    }
    catch {
        Log-Error "Failed to get ISS crew: $_"
        return Err "Failed to get ISS crew information"
    }
}

function Get-ISSPasses {
    param(
        [PSCustomObject]$Location
    )
    
    try {
        if (-not $Location.lat -or -not $Location.lon) {
            return Err "Invalid location object. Must contain lat and lon properties"
        }
        
        $url = "http://api.open-notify.org/iss-pass.json?lat=$($Location.lat)&lon=$($Location.lon)&n=5"
        $response = Invoke-WebRequest $url -userAgent "curl" -useBasicParsing
        $passes = $response.Content | ConvertFrom-Json
        
        Write-Host ""
        Write-Host "🔭 ISS Pass Predictions for $($Location.City), $($Location.Country)" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        
        foreach ($pass in $passes.response) {
            $datetime = (Get-Date '1970-01-01').AddSeconds($pass.risetime).ToLocalTime()
            $duration = [TimeSpan]::FromSeconds($pass.duration)
            
            Write-Host "📅 Date: " -NoNewline -ForegroundColor Yellow
            Write-Host $datetime.ToString("yyyy-MM-dd HH:mm:ss") -ForegroundColor White
            Write-Host "⏱️  Duration: " -NoNewline -ForegroundColor Yellow
            Write-Host "$($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor White
            Write-Host ""
        }
        
        return Ok -Value $passes -Message "ISS pass predictions retrieved"
    }
    catch {
        Log-Error "Failed to get ISS passes: $_"
        return Err "Failed to get ISS pass predictions"
    }
}

function Show-ISSArt {
    $art = @"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%#####################%****%#####################%
%###%*!!*%%*!!*%######!    !######%*!!*%%*!!*%###%
%###* -: !* =. %#######%..%#######% := *! :- *###%
%###* -- !* =. %###+---:  :---+###% := *! -- *###%
%###* -- !* =: %###%!!!=  =!!!%###% := *! -- *###%
%###* -- %* =: %#######!  !#######% := *% -- *###%
%###%++-:++:--:+*******-  -*******+:--:++:-++%###%
%###%%*:-=--::-==------:  :----:-==--:-==-:*%%###%
%###* -- %* +: %#* -::*!  **::- *#% -= *% -- *###%
%###* -: !* =. %#+ . .--  --. : +#% := *! -- *###%
%###* -- !* =: %#*:=-==+  +==-=:*#% := *! -- *###%
%###* :: !* =. %#####+==..==+#####% .- *! :: *###%
%###!-++-%!-*+-%#####:  ..  :#####%-+*-!%-++-!###%
%####################!++  ++*####################%
%##################+=++=  =++=+##################%
%##################%%%%!  !%%%%##################%
%######################%  %######################%
%#######################!!%######################%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
`n
"@
    # Convert each line to an array, iterate the array and call WriteLine for each line
    $art -split "`n" | ForEach-Object { WriteLine $_ 0.1 }
    Write-Host "Welcome to ISS Tracker!" -ForegroundColor Yellow
}

function Show-SimpleISSMap {
    param (
        [double]$Latitude,
        [double]$Longitude,
        [double]$UserLat = $null,
        [double]$UserLon = $null
    )

    $mapWidth = 64   # wider for 16:9 feel
    $mapHeight = 27  # ≈ 16:9
    $map = @()

    # Initialize map with dots
    for ($y = 0; $y -lt $mapHeight; $y++) {
        $map += ("·" * $mapWidth)
    }

    function Convert-ToMapXY($lat, $lon) {
        $x = [Math]::Round(($lon + 180) * ($mapWidth - 1) / 360)
        $y = [Math]::Round((90 - $lat) * ($mapHeight - 1) / 180)
        $x = [Math]::Max(0, [Math]::Min($mapWidth - 2, $x))  # leave space for emoji width
        $y = [Math]::Max(0, [Math]::Min($mapHeight - 1, $y))
        return @{ x = $x; y = $y }
    }

    function Set-WideSymbol {
        param (
            [string[]]$Map,
            [int]$X,
            [int]$Y,
            [string]$Symbol
        )
        $row = $Map[$Y]
        $prefix = $row.Substring(0, $X)
        $suffix = if ($X + 2 -lt $row.Length) { $row.Substring($X + 2) } else { "" }
        $Map[$Y] = $prefix + $Symbol + $suffix
        return $Map
    }

    $issPos = Convert-ToMapXY -lat $Latitude -lon $Longitude
    $map = Set-WideSymbol -Map $map -X $issPos.x -Y $issPos.y -Symbol "🛰️"

    if ($UserLat -ne $null -and $UserLon -ne $null) {
        $userPos = Convert-ToMapXY -lat $UserLat -lon $UserLon
        $map = Set-WideSymbol -Map $map -X $userPos.x -Y $userPos.y -Symbol "🏠"
    }

    Write-Host "`n🌍 Earth Map (ISS + You)" -ForegroundColor Cyan
    Write-Host ("─" * ($mapWidth + 2)) -ForegroundColor DarkGray
    foreach ($row in $map) {
        Write-Host "│$row│" -ForegroundColor DarkGray
    }
    Write-Host ("─" * ($mapWidth + 2)) -ForegroundColor DarkGray
    Write-Host "Legend: 🛰️ = ISS, 🏠 = You`n"
}

$earthMap = @'
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣴⣾⣿⣿⣿⣿⣿⡿⠒⠚⠒⠛⣲⣶⠆⠀⠠⣶⡦⠀⠀⠿⣷⣦⡀⢠⣤⣼⣦⡤⣄⡀⢀⢀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⢀⣤⡶⠒⢛⡲⠿⣿⣿⢿⡿⢿⣿⣿⣿⣿⣧⣽⣿⠂⣀⣠⣾⣿⡄⠀⢀⣤⣼⣿⣿⣷⣶⡿⠿⠻⣿⡿⠁⠀⠀⠉⠉⠉⠙⠛⠋⠙⠛⠒⢲⠖⠶⣦⣄⠀⠀⠀
⠀⢏⡭⠶⣴⡏⠀⠀⠙⠚⠉⠀⣶⣿⡿⠻⢿⡏⠘⠷⠾⠟⠉⠙⢿⣿⣿⣾⣿⣷⣿⣿⡉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⠴⣾⢦⣾⠋⠀⠀⠀
⠁⠀⠀⠀⣿⣧⡤⠤⠤⠄⣦⣀⡀⠛⢁⣠⣤⣿⠆⠀⠀⠀⠀⠀⠘⢿⣯⠿⣟⣯⣉⠀⠑⣤⠀⣤⡤⣆⠈⠉⠓⢦⣤⡤⠔⠯⠠⣔⠀⢌⡉⢷⣞⢳⡇⠀⠀⠀⠀
⠀⠀⠀⢰⡟⠁⠀⠀⠀⠀⠹⠿⢟⣦⡿⠟⠋⠉⠀⠀⠀⠀⠀⠀⢠⡟⢻⣶⣿⣿⣧⣼⣿⠿⢶⣿⣿⣿⣇⣤⣯⠏⠀⠑⠒⠢⠄⠋⢠⣀⣴⣾⣿⣿⠀⠀⠀⠀⠀
⠀⠀⠀⠸⣯⡀⣀⠀⠀⠀⠀⣠⡾⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣨⡗⠞⠋⢿⢿⣿⣿⣿⣶⡜⢻⡉⠉⢇⢩⠿⠷⣆⠀⠀⠀⠀⠀⠈⠹⣿⣿⣿⠿⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣿⣧⠈⢱⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⡿⠡⠀⠀⢸⣄⡀⢁⠈⣻⡄⠈⢻⣶⣼⣯⣤⠀⠈⠻⣷⠸⣄⣀⠀⣠⣿⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠛⢧⣼⣟⡿⣏⠻⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⣯⣡⢰⣈⣷⠋⡐⠈⡉⠀⠀⣿⣄⣄⣾⡿⠉⢿⡄⢠⣾⠿⣷⡟⠻⣿⠉⢿⡆⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠣⢀⠒⠉⠛⣽⣶⣄⡀⠀⠀⠀⠀⠉⠛⠉⠻⣿⡶⠏⠉⢹⡟⢁⣴⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢁⣤⠟⠋⠙⠿⢿⡀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⡀⣾⣀⠀⠀⠀⠀⠀⢹⠆⠀⠀⠀⠀⠀⠀⠀⢸⡇⠤⣀⣼⣇⢸⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢁⣤⠟⠋⠙⠿⢿⡀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢳⣬⡏⠱⡄⠀⠀⢀⡿⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⢀⣏⠹⢿⣼⡷⢻⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢁⣤⠟⠋⠙⠿⢿⡀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⡗⠒⣿⡄⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠈⢧⢰⠤⠓⣾⠗⣧⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠋⠁⠀⠀⠀⠀⠈⢳⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⢸⣴⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣦⣤⡼⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣀⣤⠤⣤⠀⠀⣠⠞⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⡀⡶⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣷⡾⠃⢀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣟⡇⣠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠋⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣟⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
'@ -split "`n"
function Convert-ToAsciiMapXY {
    param(
        [double]$lat,
        [double]$lon
    )
    Write-Host "Convert-ToAsciiMapXY received: lat=$lat ($($lat.GetType())), lon=$lon ($($lon.GetType()))"
    $mapHeight = $earthMap.Count
    $mapWidth = ($earthMap | Measure-Object -Property Length -Maximum).Maximum
    # Standard calculation
    $x = [math]::Round(($lon + 180) * ($mapWidth - 1) / 360)
    $y = [math]::Round((90 - $lat) * ($mapHeight - 1) / 180)
    ##$x -= 4  # Subtract 4 from X (move west)
    ##$y += 2  # Add 2 to Y (move south)
    # Ensure we stay within bounds
    $x = [math]::Max(0, [math]::Min($mapWidth - 2, $x))
    $y = [math]::Max(0, [math]::Min($mapHeight - 1, $y))
    Write-Host "Convert-ToAsciiMapXY calculated: x=$x, y=$y"
    return @{ x = $x; y = $y }
}
# Now update the main function to use this conversion
function Show-ISSWorldMap {
    param (
        [PSCustomObject]$ISSLocation,
        [PSCustomObject]$UserLocation = $null
    )

    # Create a copy of the earth map to modify
    $earthCopy = $earthMap.Clone()

    # Place the ISS symbol
    if ($null -ne $ISSLocation) {
        Write-Host "ISS position: Lat $($ISSLocation.lat), Lon $($ISSLocation.lon)" -ForegroundColor Cyan
        $issPos = Convert-ToAsciiMapXY $ISSLocation.lat $ISSLocation.lon
        Set-WideSymbol -MapRef $earthCopy -X $issPos.x -Y $issPos.y -Symbol "🛰️"
        Write-Host "ISS placed at map position: ($($issPos.x), $($issPos.y))" -ForegroundColor DarkGray
    }

    # Place the user's location if provided
    if ($null -ne $UserLocation) {
        Write-Host "Your position: Lat $($UserLocation.LatitudeDouble), Lon $($UserLocation.LongitudeDouble)" -ForegroundColor Cyan
        $userPos = Convert-ToAsciiMapXY -lat $UserLocation.LatitudeDouble -lon $UserLocation.LongitudeDouble
        Set-WideSymbol -MapRef $earthCopy -X $userPos.x -Y $userPos.y -Symbol "🏠"
        Write-Host "You placed at map position: ($($userPos.x), $($userPos.y))" -ForegroundColor DarkGray
    }

    # Display the map
    Write-Host "`n🗺️  Stylized Earth Map" -ForegroundColor Cyan
    $earthCopy | ForEach-Object { Write-Host $_ }
    Write-Host "`nLegend: 🛰️ = ISS, 🏠 = You"
}

# Helper function
function Set-WideSymbol {
    param ($MapRef, $X, $Y, $Symbol)
    
    # Safety check
    if ($Y -ge 0 -and $Y -lt $MapRef.Count -and $X -ge 0 -and ($X + 1) -lt $MapRef[$Y].Length) {
        $row = $MapRef[$Y]
        $MapRef[$Y] = $row.Substring(0, $X) + $Symbol + $row.Substring($X + 2)
    }
}

function Show-ISSMap {
    $result = Get-ISSPosition
    if ($result.ok) {
        $lat = $result.Value.iss_position.latitude
        $lon = $result.Value.iss_position.longitude
        # Open in browser with a map service
        $url = "https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=4/$lat/$lon"
        all my browser $url
        Write-Host "🗺️ Opening ISS location in browser..." -ForegroundColor Cyan
        return Ok -Message "Map opened in browser"
    } else {
        return $result
    }
}

function Show-ISSHelp {
    Write-Host ""
    Write-Host "🛰️ ISS Tracker Commands" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "all my homies luv iss               " -NoNewline -ForegroundColor Yellow
    Write-Host "# Current position"
    Write-Host "all my homies luv iss track         " -NoNewline -ForegroundColor Yellow
    Write-Host "# Real-time tracking"
    Write-Host "all my homies luv iss crew          " -NoNewline -ForegroundColor Yellow
    Write-Host "# Current crew info"
    Write-Host "all my homies luv iss pass          " -NoNewline -ForegroundColor Yellow
    Write-Host "# Pass predictions"
    Write-Host "all my homies luv iss art           " -NoNewline -ForegroundColor Yellow
    Write-Host "# Show ASCII art"
    Write-Host "all my homies luv iss map           " -NoNewline -ForegroundColor Yellow
    Write-Host "# Open in browser"
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -Location <location>    # Location object from 'all my location'"
    Write-Host "  -UpdateInterval <sec>  # For tracking (default: 5)"
    Write-Host ""
    
    return Ok -Message "Help displayed"
}
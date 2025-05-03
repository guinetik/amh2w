function weather {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Location to fetch weather report for",
            Position = 0
        )]
        [string] $Location
    )

    try {
        Write-Host "Fetching weather report..." -ForegroundColor Cyan
        Write-Progress "Fetching weather report..." -Status "Calling wttr.in API"

        $url = "http://wttr.in/${Location}?format=j1"
        Log-Debug "Fetching weather report from $url"
        $response = Invoke-WebRequest -Uri $url -UserAgent "curl" -UseBasicParsing -ErrorAction Stop
        $weather = $response.Content | ConvertFrom-Json

        $current = $weather.current_condition
        $area    = $weather.nearest_area

        $temp     = "$($current.temp_C)°C"
        $precip   = "$($current.precipMM) mm"
        $humidity = "$($current.humidity)%"
        $pressure = "$($current.pressure) hPa"
        $wind     = "$($current.windspeedKmph) km/h from $($current.winddir16Point)"
        $uv       = $current.uvIndex
        $visib    = "$($current.visibility) km"
        $clouds   = "$($current.cloudcover)%"
        $desc     = $current.weatherDesc[0].value
        $areaName = $area[0].areaName[0].value
        $region   = $area[0].region[0].value

        Write-Progress "Done" -Completed
        Write-Host "`n☁️  Weather Report for $areaName ($region)" -ForegroundColor Cyan
        Write-Host "---------------------------------------------------" -ForegroundColor Cyan
        Write-Host "🌡️ Temperature                  : $temp"
        Write-Host "🌧️ Precipitation                : $precip"
        Write-Host "💧 Humidity                     : $humidity"
        Write-Host "🌬️ Wind                         : $wind"
        Write-Host "🌤️ Conditions                   : $desc"
        Write-Host "🔭 Visibility                   : $visib"
        Write-Host "☁️ Cloud Cover                  : $clouds"
        Write-Host "📈 Pres sure                    : $pressure"
        Write-Host "🔆 UV Index                     : $uv"

        return Ok -Value ([PSCustomObject]@{
            Temperature = $temp
            Precipitation = $precip
            Humidity = $humidity
            Pressure = $pressure
            Wind = $wind
            Description = $desc
            Visibility = $visib
            CloudCover = $clouds
            UVIndex = $uv
            Location = "$areaName, $region"
        }) -Message "Weather fetched successfully"
    }
    catch {
        return Err -Msg "Weather check failed: $_"
    }
}

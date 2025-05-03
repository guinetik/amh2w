function location {
    [CmdletBinding()]
    param()

    try {
        $response = Invoke-WebRequest -Uri "http://ifconfig.co/json" -UserAgent "curl" -UseBasicParsing -ErrorAction Stop
        $data = $response.Content | ConvertFrom-Json

        $info = [PSCustomObject]@{
            Latitude  = "$($data.latitude)°"
            Longitude = "$($data.longitude)°"
            Zip       = $data.zip_code
            City      = $data.city
            Region    = $data.region_name
            Country   = $data.country
            IP        = $data.ip
        }

        Write-Host "🌐 Found location from public IP"
        Write-Host "📍 $($info.Latitude), $($info.Longitude) near $($info.Zip) $($info.City) in $($info.Region), $($info.Country)." -ForegroundColor Cyan

        return Ok -Value $info -Message "Location determined from public IP"
    }
    catch {
        return Err -Msg "Failed to retrieve location: $_"
    }
}

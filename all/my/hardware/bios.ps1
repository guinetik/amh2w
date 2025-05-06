function bios {
    try {
        Write-Progress "Querying BIOS details..."

        if ($IsLinux) {
            $model = (sudo dmidecode -s system-product-name 2>$null).Trim()
            if (-not $model) { return Err -Message "No BIOS information available" }

            $version      = (sudo dmidecode -s bios-version 2>$null).Trim()
            $releaseDate  = (sudo dmidecode -s bios-release-date 2>$null).Trim()
            $manufacturer = (sudo dmidecode -s system-manufacturer 2>$null).Trim()
            $serial       = (sudo dmidecode -s system-serial-number 2>$null).Trim()
        }
        else {
            $details = Get-CimInstance -ClassName Win32_BIOS
            $model        = $details.Name.Trim()
            $version      = $details.Version.Trim()
            $releaseDate  = $details.ReleaseDate
            $serial       = $details.SerialNumber.Trim()
            $manufacturer = $details.Manufacturer.Trim()

            # Format WMI datetime if needed
            if ($releaseDate -match '^\d{14}\.\d{6}\+\d{3}$') {
                $releaseDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($releaseDate).ToShortDateString()
            }
        }

        # Normalize common junk values
        foreach ($val in 'model','version','serial','manufacturer') {
            if ((Get-Variable $val -ValueOnly) -match "To be filled by O\.E\.M\." -or -not (Get-Variable $val -ValueOnly)) {
                Set-Variable -Name $val -Value "N/A"
            }
        }

        if (-not $releaseDate) { $releaseDate = "N/A" }

        Write-Progress "Done" -Completed

        Write-Host "`n🧬 BIOS Information:" -ForegroundColor Cyan
        Write-Host "---------------------" -ForegroundColor Cyan
        Write-Host "Model       : $model"
        Write-Host "Version     : $version"
        Write-Host "Release Date: $releaseDate"
        Write-Host "Serial No.  : $serial"
        Write-Host "Manufacturer: $manufacturer"

        $biosObj = [PSCustomObject]@{
            Model        = $model
            Version      = $version
            ReleaseDate  = $releaseDate
            SerialNumber = $serial
            Manufacturer = $manufacturer
        }

        return Ok -Value $biosObj
    }
    catch {
        return Err -Message "BIOS check failed: $_"
    }
}

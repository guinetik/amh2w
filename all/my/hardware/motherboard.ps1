function motherboard {
    try {
        if ($IsLinux) {
            return Err -Message "Linux motherboard support is not yet implemented"
        }

        $boards = Get-WmiObject -Class Win32_BaseBoard
        if (-not $boards) {
            return Err -Message "No motherboard information found"
        }

        Write-Host "`n🧩 Motherboard Info:" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor Cyan

        $result = @()
        $i = 1

        foreach ($board in $boards) {
            $manufacturer = $board.Manufacturer.Trim()
            $product      = $board.Product.Trim()
            $version      = $board.Version.Trim()
            $serial       = $board.SerialNumber.Trim()
            $assetTag     = $board.Tag.Trim()

            foreach ($val in @('manufacturer','product','version','serial')) {
                if ((Get-Variable $val -ValueOnly) -match "To be filled by O\.E\.M\." -or -not (Get-Variable $val -ValueOnly)) {
                    Set-Variable -Name $val -Value "N/A"
                }
            }

            Write-Host "`n[$i] $product" -ForegroundColor Yellow
            Write-Host "  Manufacturer : $manufacturer"
            Write-Host "  Version      : $version"
            Write-Host "  Serial       : $serial"
            Write-Host "  Asset Tag    : $assetTag"

            $result += [PSCustomObject]@{
                Product      = $product
                Manufacturer = $manufacturer
                Version      = $version
                SerialNumber = $serial
                AssetTag     = $assetTag
            }

            $i++
        }

        return Ok -Value $result
    }
    catch {
        return Err -Message "Motherboard info failed: $_"
    }
}

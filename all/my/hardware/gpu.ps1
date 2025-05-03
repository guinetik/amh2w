function gpu {
    function Bytes2String {
        param([int64]$Bytes)
        if ($Bytes -lt 1KB)   { return "$Bytes B" }
        if ($Bytes -lt 1MB)   { return "{0:N0} KB" -f ($Bytes / 1KB) }
        if ($Bytes -lt 1GB)   { return "{0:N1} MB" -f ($Bytes / 1MB) }
        if ($Bytes -lt 1TB)   { return "{0:N1} GB" -f ($Bytes / 1GB) }
        return "{0:N1} TB" -f ($Bytes / 1TB)
    }

    try {
        if ($IsLinux) {
            return Err -Message "Linux GPU support is not yet implemented"
        }

        $gpus = Get-WmiObject Win32_VideoController
        if (-not $gpus) {
            return Err -Message "No GPU devices found"
        }

        Write-Host "`n🎮 GPU Information:" -ForegroundColor Cyan
        Write-Host "-------------------" -ForegroundColor Cyan

        $gpuList = @()
        $i = 1

        foreach ($gpu in $gpus) {
            $model         = $gpu.Caption.Trim()
            $ram           = Bytes2String($gpu.AdapterRAM)
            $res           = "$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)"
            $bpp           = "$($gpu.CurrentBitsPerPixel)-bit"
            $hz            = "$($gpu.CurrentRefreshRate)Hz"
            $driverVersion = $gpu.DriverVersion
            $status        = $gpu.Status

            Write-Host "`n[$i] $model" -ForegroundColor Yellow
            Write-Host "  RAM       : $ram"
            Write-Host "  Resolution: $res"
            Write-Host "  Color     : $bpp"
            Write-Host "  Refresh   : $hz"
            Write-Host "  Driver    : $driverVersion"
            Write-Host "  Status    : $status"

            $gpuList += [PSCustomObject]@{
                Model         = $model
                Memory        = $ram
                Resolution    = $res
                ColorDepth    = $bpp
                RefreshRate   = $hz
                DriverVersion = $driverVersion
                Status        = $status
            }

            $i++
        }

        return Ok -Value $gpuList
    }
    catch {
        return Err -Message "GPU check failed: $_"
    }
}

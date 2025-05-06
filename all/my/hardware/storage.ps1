function storage {
    param([int64]$minLevel = 5GB)

    function Bytes2String {
        param([int64]$bytes)
        switch ($bytes) {
            {$_ -lt 1KB} { return "$bytes B" }
            {$_ -lt 1MB} { return "{0:N0} KB" -f ($bytes / 1KB) }
            {$_ -lt 1GB} { return "{0:N0} MB" -f ($bytes / 1MB) }
            {$_ -lt 1TB} { return "{0:N0} GB" -f ($bytes / 1GB) }
            default     { return "{0:N2} TB" -f ($bytes / 1TB) }
        }
    }

    try {
        Write-Progress "Querying drives..."

        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }
        $result = @()
        $status = "✅"

        Write-Host "`n💾 Storage Devices:" -ForegroundColor Cyan
        Write-Host "-------------------" -ForegroundColor Cyan

        foreach ($drive in $drives) {
            $free = [int64]$drive.Free
            $used = [int64]$drive.Used
            $total = $used + $free
            $percentUsed = if ($total -gt 0) { [math]::Round(($used * 100) / $total, 1) } else { 0 }

            $label = if ($IsLinux) { $drive.Name } else { "$($drive.Name):" }
            $alert = ""
            $color = "Gray"

            if ($total -eq 0) {
                $alert = "EMPTY"
                $color = "DarkGray"
                $status = "⚠️"
            }
            elseif ($free -eq 0) {
                $alert = "FULL"
                $color = "Red"
                $status = "⚠️"
            }
            elseif ($free -lt $minLevel) {
                $alert = "LOW SPACE"
                $color = "Yellow"
                $status = "⚠️"
            }
            else {
                $alert = "OK"
                $color = "Green"
            }

            # Output summary
            Write-Host "`n$label ($alert)" -ForegroundColor $color
            Write-Host "  Total : $(Bytes2String $total)"
            Write-Host "  Used  : $(Bytes2String $used) ($percentUsed%)"
            Write-Host "  Free  : $(Bytes2String $free)"

            # Append structured result
            $result += [PSCustomObject]@{
                Drive     = $label
                Total     = $total
                Used      = $used
                Free      = $free
                UsedPct   = $percentUsed
                Alert     = $alert
            }
        }

        Write-Progress "Done" -Completed
        return Ok -Value $result -Message "Drive check complete"
    }
    catch {
        return Err -Message "Drive check failed: $_"
    }
}

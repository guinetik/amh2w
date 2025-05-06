function power {
    try {
        if ($IsLinux) {
            # TODO: Implement detection from /sys/class/power_supply or upower
            $reply = "✅ AC powered (assumed)"
            WriteLine $reply
            return Ok -Value $reply
        }

        Add-Type -AssemblyName System.Windows.Forms
        $status = [System.Windows.Forms.SystemInformation]::PowerStatus

        $percent = [int]($status.BatteryLifePercent * 100)
        $remaining = [int]($status.BatteryLifeRemaining / 60)

        # Get current power scheme name
        $powerScheme = (powercfg /getactivescheme 2>$null) -replace '^.*\((.*)\)$', '$1'

        $ac = $status.PowerLineStatus -eq "Online"
        $noBattery = $status.BatteryChargeStatus -eq "NoSystemBattery"

        $reply = ""
        $emoji = "✅"

        if ($ac) {
            if ($noBattery) {
                $reply = "AC powered — no battery detected"
            }
            elseif ($percent -ge 90) {
                $reply = "Battery $percent% full and plugged in"
            }
            else {
                $reply = "Charging — battery at $percent%"
            }
        }
        else {
            if ($noBattery) {
                $reply = "Battery missing or not reporting"
            }
            elseif ($remaining -eq 0) {
                $reply = "Battery at $percent% (no estimate)"
            }
            elseif ($remaining -le 5) {
                $emoji = "🔴"
                $reply = "LOW battery! $percent% — only $remaining min left"
            }
            elseif ($remaining -le 30) {
                $emoji = "⚠️"
                $reply = "Battery low — $percent%, $remaining min remaining"
            }
            else {
                $reply = "Running on battery — $percent% ($remaining min remaining)"
            }
        }

        $summary = "$emoji $reply (power scheme: '$powerScheme')"
        Write-Host $summary
        return Ok -Value $summary
    }
    catch {
        return Err -Message "Power check failed: $_"
    }
}

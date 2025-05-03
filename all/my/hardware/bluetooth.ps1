function bluetooth {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("list", "enable", "disable", "restart")]
        [string]$Action = "list",

        [Parameter(Position = 1)]
        [string]$InstanceId
    )

    try {
        switch ($Action) {
            "list" {
                $raw = Get-PnpDevice | Where-Object { $_.Class -eq "Bluetooth" } | Sort-Object FriendlyName

                if (-not $raw) {
                    Write-Host "⚠️ No Bluetooth devices found." -ForegroundColor Yellow
                    return Err -Message "No devices found"
                }

                $jsonObject = $raw | ForEach-Object {
                    [PSCustomObject]@{
                        Name       = $_.FriendlyName
                        Status     = $_.Status
                        InstanceId = $_.InstanceId
                    }
                }

                Show-JsonTable $jsonObject

                return Ok -Value $jsonObject -Message "$($jsonObject.Count) Bluetooth device(s) listed"
            }

            "enable" {
                if (-not $InstanceId) {
                    return Err -Message "Missing InstanceId for enable"
                }
                Enable-PnpDevice -InstanceId $InstanceId -Confirm:$false
                Write-Host "✅ Enabled Bluetooth device: $InstanceId" -ForegroundColor Green
                return Ok -Message "Device enabled"
            }

            "disable" {
                if (-not $InstanceId) {
                    return Err -Message "Missing InstanceId for disable"
                }
                Disable-PnpDevice -InstanceId $InstanceId -Confirm:$false
                Write-Host "✅ Disabled Bluetooth device: $InstanceId" -ForegroundColor Yellow
                return Ok -Message "Device disabled"
            }

            "restart" {
                if (-not $InstanceId) {
                    return Err -Message "Missing InstanceId for restart"
                }
                Restart-PnpDevice -InstanceId $InstanceId -Confirm:$false
                Write-Host "🔄 Restarted Bluetooth device: $InstanceId" -ForegroundColor Cyan
                return Ok -Message "Device restarted"
            }
        }
    }
    catch {
        return Err -Message "Bluetooth command failed: $_"
    }
}

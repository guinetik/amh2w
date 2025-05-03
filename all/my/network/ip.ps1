function ip {
    [CmdletBinding()]
    param(
        [ValidateSet("all", "interfaces", "neighbors", "shares", "netstat", "routes", "ipv6")]
        [string]$Action = "all"
    )

    try {
        function Section($title) {
            Write-Host "`n🌐 $title" -ForegroundColor Cyan
            Write-Host ("=" * (2 + $title.Length)) -ForegroundColor Cyan
        }

        if ($Action -eq "interfaces" -or $Action -eq "all") {
            Section "Local Interfaces"
            $ifaces = @("Ethernet", "WLAN", "Bluetooth")
            $addresses = Get-NetIPAddress

            $json = foreach ($iface in $ifaces) {
                $ipv4 = $ipv6 = $prefix = ""
                foreach ($addr in $addresses) {
                    if ($addr.InterfaceAlias -like "$iface*") {
                        if ($addr.AddressFamily -eq "IPv4") {
                            $ipv4 = $addr.IPAddress
                            $prefix = $addr.PrefixLength
                        } elseif ($addr.AddressFamily -eq "IPv6") {
                            $ipv6 = $addr.IPAddress
                        }
                    }
                }

                if ($ipv4 -or $ipv6) {
                    [PSCustomObject]@{
                        Interface = $iface
                        IPv4      = if ($ipv4) { "$ipv4/$prefix" } else { "-" }
                        IPv6      = if ($ipv6) { $ipv6 } else { "-" }
                    }
                }
            }

            Show-JsonTable $json
        }

        if ($Action -eq "ipv6" -or $Action -eq "all") {
            Section "IPv6 Bindings"
            $bindings = Get-NetAdapterBinding -Name '*' -ComponentID 'ms_tcpip6' | Sort-Object Name
            $json = $bindings | ForEach-Object {
                [PSCustomObject]@{
                    Name    = $_.Name
                    IPv6    = if ($_.Enabled) { "Enabled" } else { "Disabled" }
                }
            }
            Show-JsonTable $json
        }

        if ($Action -eq "neighbors" -or $Action -eq "all") {
            Section "Network Neighbors"
            if ($IsLinux -or $IsMacOS) {
                Write-Host "❌ Not implemented on this OS" -ForegroundColor Yellow
            } else {
                $neighbors = Get-NetNeighbor -IncludeAllCompartments -State Permanent,Reachable
                $json = $neighbors | ForEach-Object {
                    [PSCustomObject]@{
                        IP        = $_.IPAddress
                        Interface = $_.InterfaceAlias
                        MAC       = $_.LinkLayerAddress
                        State     = $_.State
                    }
                }
                Show-JsonTable $json
            }
        }

        if ($Action -eq "routes" -or $Action -eq "all") {
            Section "Routing Table"
            route print | Out-Host
        }

        if ($Action -eq "netstat" -or $Action -eq "all") {
            Section "Active Connections (netstat)"
            netstat -n | Out-Host
        }

        if ($Action -eq "shares" -or $Action -eq "all") {
            Section "Shared Folders"
            if ($IsLinux) {
                Write-Host "❌ Not implemented on this OS" -ForegroundColor Yellow
            } else {
                $shares = Get-WmiObject Win32_Share | Where-Object { $_.Name -notlike '*$' }
                $json = $shares | ForEach-Object {
                    [PSCustomObject]@{
                        Name        = $_.Name
                        Path        = $_.Path
                        Description = $_.Description
                        Share       = "\\$env:COMPUTERNAME\$($_.Name)"
                    }
                }
                Show-JsonTable $json
            }
        }

        return Ok -Message "IP diagnostics complete"
    }
    catch {
        return Err -Msg "IP diagnostics failed: $_"
    }
}
# DNS Module - Network DNS management
# Provides DNS testing, configuration, and optimization features

# DNS Provider Database
function Get-DNSProviders {
    # TODO: Improve this to come from a service or something
    return @(
        @{Name="AdGuard DNS (Cyprus)"; Primary="94.140.14.14"; Secondary="94.140.15.15"},
        @{Name="CleanBrowsing"; Primary="185.228.168.9"; Secondary="185.228.169.9"},
        @{Name="Cloudflare Public DNS (USA, standard)"; Primary="1.1.1.1"; Secondary="1.0.0.1"},
        @{Name="Cloudflare Public DNS (with malware blocklist)"; Primary="1.1.1.2"; Secondary="1.0.0.2"},
        @{Name="Cloudflare Public DNS (with malware+adult blocklist)"; Primary="1.1.1.3"; Secondary="1.0.0.3"},
        @{Name="Control D (Canada)"; Primary="76.76.2.0"; Secondary="76.76.10.0"},
        @{Name="DNS0.eu (standard)"; Primary="193.110.81.0"; Secondary="185.253.5.0"},
        @{Name="DNS0.eu (for kids)"; Primary="193.110.81.1"; Secondary="185.253.5.1"},
        @{Name="DNS0.eu (zero)"; Primary="193.110.81.9"; Secondary="185.253.5.9"},
        @{Name="Google Public DNS (USA)"; Primary="8.8.8.8"; Secondary="8.8.4.4"},
        @{Name="Level3 one"; Primary="4.2.2.1"; Secondary="4.2.2.1"},
        @{Name="Level3 two"; Primary="4.2.2.2"; Secondary="4.2.2.2"},
        @{Name="Level3 three"; Primary="4.2.2.3"; Secondary="4.2.2.3"},
        @{Name="Level3 four"; Primary="4.2.2.4"; Secondary="4.2.2.4"},
        @{Name="Level3 five"; Primary="4.2.2.5"; Secondary="4.2.2.5"},
        @{Name="Level3 six"; Primary="4.2.2.6"; Secondary="4.2.2.6"},
        @{Name="OpenDNS (basic)"; Primary="208.67.222.222"; Secondary="208.67.220.220"},
        @{Name="OpenDNS (family shield)"; Primary="208.67.222.123"; Secondary="208.67.220.123"},
        @{Name="OpenNIC Project"; Primary="94.247.43.254"; Secondary="94.247.43.254"},
        @{Name="Quad9 (with malware blocklist, with DNSSEC)"; Primary="9.9.9.9"; Secondary="149.112.112.112"},
        @{Name="Quad9 (no malware blocklist, no DNSSEC)"; Primary="9.9.9.10"; Secondary="9.9.9.10"},
        @{Name="Quad9 (with malware blocklist, with DNSSEC, with EDNS)"; Primary="9.9.9.11"; Secondary="9.9.9.11"},
        @{Name="Quad9 (with malware blocklist, with DNSSEC, NXDOMAIN only)"; Primary="9.9.9.12"; Secondary="9.9.9.12"},
        @{Name="Verisign Public DNS (USA)"; Primary="64.6.64.6"; Secondary="64.6.65.6"}
    ) 
}

# Test Domain List
function Get-TestDomains {
    param([string]$Type = "standard")
    
    switch ($Type) {
        "quick" { return @("google.com", "microsoft.com", "amazon.com", "cloudflare.com", "github.com") }
        "standard" { return @("google.com", "microsoft.com", "amazon.com", "cloudflare.com", "github.com", "stackoverflow.com", "facebook.com", "youtube.com", "twitter.com", "reddit.com") }
        default { return @("google.com", "microsoft.com", "amazon.com", "cloudflare.com", "github.com") }
    }
}

# Active Network Adapters
function Get-ActiveNetworkAdapters {
    return Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
}

# DNS Configuration Functions
function Get-CurrentDNSConfiguration {
    try {
        $adapters = Get-ActiveNetworkAdapters
        $config = @{}
        
        foreach ($adapter in $adapters) {
            $dnsServers = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
            $config[$adapter.ifIndex] = @{
                AdapterName = $adapter.Name
                Servers = $dnsServers.ServerAddresses
            }
        }
        
        return $config
    } catch {
        Log-Error "Failed to get current DNS configuration: $_"
        return $null
    }
}

function Set-DNSConfiguration {
    param(
        [string]$Primary,
        [string]$Secondary
    )
    
    try {
        $adapters = Get-ActiveNetworkAdapters
        foreach ($adapter in $adapters) {
            Log-Info "🔧 Setting DNS for adapter: $($adapter.Name)"
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @($Primary, $Secondary)
        }
        return $true
    } catch {
        Log-Error "Failed to set DNS configuration: $_"
        return $false
    }
}

# DNS Testing Functions
function Test-DNSSpeed {
    param(
        [string[]]$Domains = (Get-TestDomains -Type "standard")
    )
    
    try {
        $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        if ($IsLinux) {
            foreach ($domain in $Domains) { 
                $null = dig $domain +short 2>$null
            }
        } else {
            Clear-DnsClientCache
            foreach ($domain in $Domains) { 
                $null = Resolve-DnsName $domain -ErrorAction SilentlyContinue
            }
        }
        
        $stopWatch.Stop()
        $totalMs = [float]$stopWatch.Elapsed.TotalMilliseconds
        $averageMs = [math]::Round($totalMs / $Domains.Length, 1)
        
        return @{
            TotalMs = $totalMs
            AverageMs = $averageMs
            DomainCount = $Domains.Length
        }
    } catch {
        Log-Error "DNS speed test failed: $_"
        return $null
    }
}

function Get-DNSSpeedRating {
    param([float]$SpeedMs)
    
    if ($SpeedMs -lt 10.0) { return @{Rating="Excellent"; Color="Green"; Emoji="✅"} }
    elseif ($SpeedMs -lt 100.0) { return @{Rating="Good"; Color="Yellow"; Emoji="✅"} }
    else { return @{Rating="Slow"; Color="Red"; Emoji="⚠️"} }
}

# Provider Search Functions
function Find-DNSProvider {
    param([string]$SearchTerm)

    $providers = Get-DNSProviders
    $normalizedSearch = $SearchTerm.ToLower()

    # 1. Exact match
    $exact = $providers | Where-Object { $_.Name -eq $SearchTerm } | Select-Object -First 1
    if ($exact) { return $exact }

    # 2. Starts with
    $startsWith = $providers | Where-Object { $_.Name.ToLower().StartsWith($normalizedSearch) } | Select-Object -First 1
    if ($startsWith) { return $startsWith }

    # 3. Contains
    $contains = $providers | Where-Object { $_.Name.ToLower().Contains($normalizedSearch) }
    if ($contains.Count -gt 0) {
        # Prefer fewer extra words: sort by Levenshtein distance or just string length diff
        return $contains | Sort-Object { [math]::Abs($_.Name.Length - $SearchTerm.Length) } | Select-Object -First 1
    }

    # 4. Multi-word fuzzy search (split input and see who matches most tokens)
    $tokens = $SearchTerm -split '\s+'
    $scored = $providers | ForEach-Object {
        $name = $_.Name.ToLower()
        $score = ($tokens | Where-Object { $name -like "*$_*" }).Count
        [PSCustomObject]@{
            Provider = $_
            Score = $score
        }
    } | Sort-Object -Property Score -Descending

    if ($scored[0].Score -gt 0) {
        return $scored[0].Provider
    }

    return $null
}

function Format-DNSInput {
    param([string]$DNSInput)
    
    # Check if it's an IP pattern (e.g., "8.8.8.8-8.8.4.4")
    if ($DNSInput -match '^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})-(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$') {
        return @{
            Type = "IP"
            Primary = $matches[1]
            Secondary = $matches[2]
        }
    }
    
    # Otherwise, search for provider
    $provider = Find-DNSProvider -SearchTerm $DNSInput
    if ($provider) {
        return @{
            Type = "Provider"
            Name = $provider.Name
            Primary = $provider.Primary
            Secondary = $provider.Secondary
        }
    }
    
    return $null
}

# Display Functions
function Show-DNSProviderList {
    $providers = Get-DNSProviders
    
    Write-Host "`n🌐 Available DNS Providers:" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    
    foreach ($provider in $providers) {
        Write-Host "`n📡 $($provider.Name)" -ForegroundColor Green
        Write-Host "   Primary:   $($provider.Primary)" -ForegroundColor Gray
        Write-Host "   Secondary: $($provider.Secondary)" -ForegroundColor Gray
    }
    
    Write-Host "`n"
}

function Show-CurrentDNSConfiguration {
    $config = Get-CurrentDNSConfiguration
    $providers = Get-DNSProviders
    
    Write-Host "`n🔍 Current DNS Configuration:" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    
    foreach ($adapterKey in $config.Keys) {
        $adapterConfig = $config[$adapterKey]
        Write-Host "`n📡 Adapter: $($adapterConfig.AdapterName)" -ForegroundColor Green
        
        if ($adapterConfig.Servers) {
            Write-Host "   DNS Servers:" -ForegroundColor Yellow
            
            $index = 1
            foreach ($server in $adapterConfig.Servers) {
                Write-Host "     $index. $server" -ForegroundColor Cyan
                
                # Check if this matches any known provider
                $matchedProvider = $providers | Where-Object { 
                    $_.Primary -eq $server -or $_.Secondary -eq $server 
                } | Select-Object -First 1
                
                if ($matchedProvider) {
                    Write-Host "        Provider: $($matchedProvider.Name)" -ForegroundColor Magenta
                }
                $index++
            }
        } else {
            Write-Host "   DNS Servers: DHCP/Automatic" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n"
}

function Show-DNSTestResults {
    param(
        [array]$Results,
        [bool]$Detailed = $false
    )
    
    Write-Host "`n📊 DNS Provider Speed Test Results:" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    
    # Sort results by speed (fastest first)
    $sortedResults = $Results | Sort-Object AverageSpeed
    
    # Create data for the chart
    $chartData = @{
        dns_speeds = $sortedResults | ForEach-Object {
            @{
                provider = $_.Name
                speed = $_.AverageSpeed
            }
        }
    }
    
    # Convert to JSON and show chart
    $jsonData = $chartData | ConvertTo-Json -Depth 10
    & all my homies hate json chart $jsonData "dns_speeds" "provider" "speed"
    if ($Detailed) {
        Write-Host "`n📝 Detailed Results:" -ForegroundColor Cyan
        foreach ($result in $sortedResults) {
            Write-Host "`n$($result.Name):" -ForegroundColor Yellow
            Write-Host "  Test Results: $($result.TestResults -join 'ms, ')ms"
            Write-Host "  Average: $($result.AverageSpeed)ms"
        }
    }
}

# Main DNS Actions
function Invoke-DNSTest {
    Log-Info "🔍 Testing DNS lookup speed..."
    $testResult = Test-DNSSpeed
    
    if ($testResult) {
        $rating = Get-DNSSpeedRating -SpeedMs $testResult.AverageMs
        Write-Host "$($rating.Emoji) Internet DNS: $($testResult.AverageMs)ms $($rating.Rating.ToLower()) lookup time" -ForegroundColor $rating.Color
        return Ok "DNS lookup speed: $($testResult.AverageMs)ms ($($rating.Rating.ToLower()))" -Value $testResult.AverageMs
    } else {
        return Err "Failed to test DNS speed"
    }
}

function Invoke-DNSSet {
    param([string]$Value)
    
    if (-not $Value) {
        return Err "Please specify DNS provider name or IP addresses (format: IP1-IP2)"
    }
    
    $parsedDNS = Format-DNSInput -DNSInput $Value
    if (-not $parsedDNS) {
        Log-Error "DNS provider '$Value' not found"
        Log-Info "💡 Use 'all my network dns list' to see available providers"
        return Err "DNS provider '$Value' not found"
    }
    
    # Elevate if needed
    if (-not (Test-IsAdmin)) {
        Log-Warning "Setting DNS requires administrator privileges"
        Invoke-Elevate -Command "all my network dns set `"$Value`"" -Description "Set DNS servers" -Prompt $true
        return
    }
    
    if (Set-DNSConfiguration -Primary $parsedDNS.Primary -Secondary $parsedDNS.Secondary) {
        if ($parsedDNS.Type -eq "Provider") {
            Log-Success "✅ DNS set to $($parsedDNS.Name)"
        } else {
            Log-Success "✅ DNS set to custom servers"
        }
        Write-Host "   Primary:   $($parsedDNS.Primary)" -ForegroundColor Cyan
        Write-Host "   Secondary: $($parsedDNS.Secondary)" -ForegroundColor Cyan
        return Ok "DNS servers updated successfully"
    } else {
        return Err "Failed to set DNS servers"
    }
}

function Invoke-DNSYolo {
    if (-not (Test-IsAdmin)) {
        Log-Warning "YOLO mode requires administrator privileges to test and set DNS"
        Invoke-Elevate -Command "all my network dns yolo" -Description "Find and set fastest DNS" -Prompt $true
        return
    }
    
    Write-Host "`n🚀 YOLO MODE: Finding the fastest DNS provider..." -ForegroundColor Magenta
    Write-Host "This will test all DNS providers and automatically set the fastest one!" -ForegroundColor Cyan
    Write-Host "Grab a coffee, this might take a while...`n" -ForegroundColor Yellow
    
    $providers = Get-DNSProviders
    $results = @()
    $originalDNS = Get-CurrentDNSConfiguration
    $testDomains = Get-TestDomains -Type "quick"
    
    try {
        foreach ($provider in $providers) {
            Write-Host "🔄 Testing $($provider.Name)..." -ForegroundColor Cyan
            
            # Set DNS to this provider
            if (-not (Set-DNSConfiguration -Primary $provider.Primary -Secondary $provider.Secondary)) {
                Write-Host "  Failed to set DNS, skipping..." -ForegroundColor Red
                continue
            }
            
            Start-Sleep -Seconds 2  # Allow DNS to settle
            
            # Run 3 tests
            $providerResults = @()
            for ($i = 1; $i -le 3; $i++) {
                Write-Host "  Test $i/3..." -ForegroundColor Gray
                $testResult = Test-DNSSpeed -Domains $testDomains
                
                if ($testResult) {
                    $providerResults += $testResult.AverageMs
                } else {
                    Write-Host "  Test failed, retrying..." -ForegroundColor Yellow
                    $testResult = Test-DNSSpeed -Domains $testDomains
                    if ($testResult) {
                        $providerResults += $testResult.AverageMs
                    }
                }
            }
            
            if ($providerResults.Count -gt 0) {
                $avgSpeed = [math]::Round(($providerResults | Measure-Object -Average).Average, 1)
                
                $results += [PSCustomObject]@{
                    Name = $provider.Name
                    Primary = $provider.Primary
                    Secondary = $provider.Secondary
                    AverageSpeed = $avgSpeed
                    TestResults = $providerResults
                }
                
                Write-Host "  Average: $($avgSpeed)ms" -ForegroundColor Yellow
            } else {
                Write-Host "  All tests failed for this provider" -ForegroundColor Red
            }
        }
        
        if ($results.Count -eq 0) {
            throw "No DNS providers could be tested successfully"
        }
        
        # Sort and display results
        $results = $results | Sort-Object AverageSpeed
        Show-DNSTestResults -Results $results
        
        # Set the fastest DNS
        $winner = $results[0]
        Write-Host "`n🏆 Winner: $($winner.Name)" -ForegroundColor Green
        Write-Host "   Average Speed: $($winner.AverageSpeed)ms" -ForegroundColor Cyan
        Write-Host "   Primary DNS: $($winner.Primary)" -ForegroundColor Cyan
        Write-Host "   Secondary DNS: $($winner.Secondary)" -ForegroundColor Cyan
        
        Write-Host "`n⚡ Setting DNS to the fastest provider..." -ForegroundColor Yellow
        
        if (Set-DNSConfiguration -Primary $winner.Primary -Secondary $winner.Secondary) {
            Log-Success "✅ DNS automatically set to $($winner.Name) - the fastest provider!"
        } else {
            throw "Failed to set winning DNS configuration"
        }
        
        # Ask for detailed results
        Write-Host "`nWant to see detailed test results for all providers? (y/N): " -ForegroundColor Cyan -NoNewline
        $showDetails = Read-Host
        
        if ($showDetails -eq 'y' -or $showDetails -eq 'Y') {
            Show-DNSTestResults -Results $results -Detailed $true
        }
        
        return Ok "YOLO mode completed! DNS set to $($winner.Name) with average speed of $($winner.AverageSpeed)ms"
        
    } catch {
        Log-Error "YOLO mode failed: $_"
        
        # Try to restore original DNS
        if ($originalDNS) {
            Write-Host "`nRestoring original DNS settings..." -ForegroundColor Yellow
            foreach ($adapterKey in $originalDNS.Keys) {
                $config = $originalDNS[$adapterKey]
                if ($config.Servers -and $config.Servers.Count -ge 2) {
                    Set-DnsClientServerAddress -InterfaceIndex $adapterKey -ServerAddresses $config.Servers -ErrorAction SilentlyContinue
                }
            }
            Log-Warning "Original DNS settings restored"
        }
        
        return Err "YOLO mode failed: $_"
    }
}

# Main DNS Command
function dns {
    param(
        [string]$Action = "check",
        [string]$Value
    )
    
    switch ($Action.ToLower()) {
        "test" { 
            return Invoke-DNSTest 
        }
        "list" { 
            Show-DNSProviderList
            return Ok "Listed $((@(Get-DNSProviders)).Count) DNS providers"
        }
        "set" { 
            return Invoke-DNSSet -Value $Value 
        }
        "check" { 
            Show-CurrentDNSConfiguration
            return Ok "DNS configuration checked"
        }
        "yolo" { 
            return Invoke-DNSYolo 
        }
        default {
            Log-Error "Invalid action. Use: test, list, set, check, or yolo"
            return Err "Invalid action. Use: test, list, set, check, or yolo"
        }
    }
}
function currency {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Currency = "USD",
        
        [Parameter(Position = 1)]
        [string]$TargetCurrency = ""
    )

    try {
        $url = "http://www.floatrates.com/daily/$($Currency.ToLower()).xml"

        Write-Host "Fetching exchange rates for $Currency..." -ForegroundColor Cyan
        
        [xml]$response = Invoke-WebRequest -Uri $url -UseBasicParsing -UserAgent "curl" | Select-Object -ExpandProperty Content
        $items = $response.channel.item

        if (-not $items) {
            return Err -Message "No exchange rates found for currency '$Currency'"
        }

        Write-Host "Processing exchange rates..." -ForegroundColor DarkGray
        
        $jsonObject = $items | ForEach-Object {
            [PSCustomObject]@{
                Rate     = [decimal]::Parse($_.exchangeRate)
                Inverse  = [decimal]::Parse($_.inverseRate)
                Currency = "$($_.targetCurrency) - $($_.targetName)"
                Code     = $_.targetCurrency
                Date     = $_.pubDate
            }
        }

        # If specific target currency is requested
        if ($TargetCurrency) {
            $targetRate = $jsonObject | Where-Object { $_.Code -eq $TargetCurrency.ToUpper() }
            
            if ($targetRate) {
                Write-Host "`n💱 Exchange Rate: $Currency ↔ $($TargetCurrency.ToUpper())" -ForegroundColor Cyan
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
                Write-Host "1 $Currency = $($targetRate.Rate) $($targetRate.Code)" -ForegroundColor Green
                Write-Host "1 $($targetRate.Code) = $($targetRate.Inverse) $Currency" -ForegroundColor Yellow
                Write-Host "Last Updated: $($targetRate.Date)" -ForegroundColor DarkGray
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
                
                # Also show a mini conversion table
                Write-Host "`n📊 Quick Conversion Table:" -ForegroundColor Cyan
                $amounts = @(1, 5, 10, 50, 100, 500, 1000)
                
                $conversionTable = $amounts | ForEach-Object {
                    [PSCustomObject]@{
                        "$Currency Amount" = $_
                        "$($targetRate.Code) Value" = [Math]::Round($_ * $targetRate.Rate, 2)
                    }
                }
                
                Show-JsonTable $conversionTable
                
                return Ok -Value $targetRate -Message "Exchange rate for $Currency to $TargetCurrency displayed"
            }
            else {
                Write-Host "`n❌ Currency '$TargetCurrency' not found in exchange rates" -ForegroundColor Red
                Write-Host "Available currencies:" -ForegroundColor Yellow
                $jsonObject | Select-Object -First 10 | ForEach-Object { Write-Host "  - $($_.Code): $($_.Currency)" }
                Write-Host "  ... and $($jsonObject.Count - 10) more" -ForegroundColor DarkGray
                
                return Err -Message "Target currency '$TargetCurrency' not found"
            }
        }
        else {
            # Sort by inverse rate (highest value first) - this shows strongest currencies first
            $sortedRates = $jsonObject | Sort-Object -Property Inverse -Descending

            Write-Host "`n🌍 Exchange Rates for 1 $Currency (via FloatRates)" -ForegroundColor Cyan
            Show-JsonTable $sortedRates

            # Create chart data for top 20 currencies by inverse rate
            $chartData = @()
            
            # Take top 20 for better chart visibility
            $topCurrencies = $sortedRates | Select-Object -First 20
            
            foreach ($curr in $topCurrencies) {
                # Use inverse rate for the chart to show currency strength
                $chartData += @{
                    currency = $curr.Code
                    rate = [Math]::Round($curr.Inverse, 4)
                }
            }

            # Convert to JSON and display chart
            if ($chartData.Count -gt 0) {
                Write-Host "`nTop 20 Currencies by Strength:" -ForegroundColor Cyan
                $jsonData = $chartData | ConvertTo-Json -Depth 10
                & all my homies hate json chart $jsonData "currency_strength" "currency" "rate"
                
                Write-Host "`nNote: Chart shows how many $Currency equal 1 unit of each currency" -ForegroundColor DarkGray
            }

            return Ok -Value $sortedRates -Message "$($jsonObject.Count) exchange rates listed and sorted by value"
        }
    }
    catch {
        return Err -Message "Failed to fetch exchange rates for '$Currency': $_"
    }
}

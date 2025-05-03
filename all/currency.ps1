function currency {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Currency = "USD"
    )

    try {
        $url = "http://www.floatrates.com/daily/$($Currency.ToLower()).xml"

        [xml]$response = Invoke-WebRequest -Uri $url -UseBasicParsing -UserAgent "curl" | Select-Object -ExpandProperty Content
        $items = $response.channel.item

        if (-not $items) {
            return Err -Msg "No exchange rates found for currency '$Currency'"
        }

        $jsonObject = $items | ForEach-Object {
            [PSCustomObject]@{
                Rate     = [decimal]::Parse($_.exchangeRate)
                Inverse  = [decimal]::Parse($_.inverseRate)
                Currency = "$($_.targetCurrency) - $($_.targetName)"
                Date     = $_.pubDate
            }
        }

        Write-Host "`n🌍 Exchange Rates for 1 $Currency (via FloatRates)" -ForegroundColor Cyan
        Show-JsonTable $jsonObject

        return Ok -Value $jsonObject -Message "$($jsonObject.Count) exchange rates listed"
    }
    catch {
        return Err -Msg "Failed to fetch exchange rates for '$Currency': $_"
    }
}
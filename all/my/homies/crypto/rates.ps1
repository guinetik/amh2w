function rates {
    [CmdletBinding()]
    param(
        [ValidateSet("rate")]
        [string]$Action = "rate"
    )

    try {
        switch ($Action) {
            "rate" {
                function Get-CryptoRate {
                    param([string]$Symbol, [string]$Name)

                    try {
                        $uri = "https://min-api.cryptocompare.com/data/price?fsym=$Symbol&tsyms=USD,EUR,BRL,JPY"
                        $data = (Invoke-WebRequest -Uri $uri -UseBasicParsing -UserAgent "curl").Content | ConvertFrom-Json
                        return [PSCustomObject]@{
                            Crypto = "$Symbol ($Name)"
                            Symbol = $Symbol
                            Name   = $Name
                            USD    = $data.USD
                            EUR    = $data.EUR
                            BRL    = $data.BRL
                            JPY    = $data.JPY
                        }
                    }
                    catch {
                        return [PSCustomObject]@{
                            Crypto = "$Symbol ($Name)"
                            Symbol = $Symbol
                            Name   = $Name
                            USD    = 0.0  # Use 0 for sorting purposes
                            EUR    = "ERR"
                            BRL    = "ERR"
                            JPY    = "ERR"
                        }
                    }
                }

                $coins = @(
                    "ADA",  "Cardano",
                    "AVAX", "Avalanche",
                    "BCH",  "Bitcoin Cash",
                    "BNB",  "Binance Coin",
                    "BTC",  "Bitcoin",
                    "BUSD", "Binance USD",
                    "DOGE", "Dogecoin",
                    "DOT",  "Polkadot",
                    "ETH",  "Ethereum",
                    "GALA", "Gala",
                    "LINK", "Chainlink",
                    "LTC",  "Litecoin",
                    "LUNA", "Terra",
                    "MATIC","Polygon",
                    "SOL",  "Solana",
                    "SUI",  "Sui",
                    "TRUMP","Official Trump",
                    "UNI",  "Uniswap",
                    "USDC", "USD Coin",
                    "USDT", "Tether",
                    "WBTC", "Wrapped Bitcoin",
                    "XLM",  "Stellar",
                    "XRP",  "XRP"
                )

                Write-Host "Fetching cryptocurrency rates..." -ForegroundColor Cyan
                $totalCoins = $coins.Count / 2
                $rates = @()
                
                for ($i = 0; $i -lt $coins.Count; $i += 2) {
                    $symbol = $coins[$i]
                    $name = $coins[$i + 1]
                    $progress = ($i / 2) + 1
                    
                    Write-Host "`rFetching [$progress/$totalCoins]: $symbol ($name)..." -NoNewline -ForegroundColor DarkGray
                    
                    $rates += Get-CryptoRate $symbol $name
                }
                
                Write-Host "`rAll rates fetched! Processing data...                    " -ForegroundColor Green

                # Sort by USD value (highest first)  
                $sortedRates = $rates | Sort-Object -Property USD -Descending

                # Display the table
                Show-JsonTable $sortedRates

                # Create chart data with log scale
                $chartData = @()
                
                # Take top 10 for better chart visibility
                $topCoins = $sortedRates | Select-Object -First 10
                
                foreach ($coin in $topCoins) {
                    if ($coin.USD -ne "ERR" -and $coin.USD -gt 0) {
                        # Use log scale for better visualization
                        $logValue = [Math]::Log10($coin.USD + 1) * 1000
                        $chartData += @{
                            crypto = $coin.Symbol
                            price = [Math]::Round($logValue, 2)
                        }
                    }
                }

                # Convert to JSON and display chart
                if ($chartData.Count -gt 0) {
                    Write-Host "`nTop 10 Cryptocurrencies (Log Scale):" -ForegroundColor Cyan
                    $jsonData = $chartData | ConvertTo-Json -Depth 10
                    & all my homies hate json chart $jsonData "crypto_prices" "crypto" "price"
                    
                    Write-Host "`nNote: Chart uses logarithmic scale for better visibility" -ForegroundColor DarkGray
                }

                Write-Host "`n(data by https://www.cryptocompare.com)" -ForegroundColor DarkGray

                return Ok -Value $sortedRates -Message "$($rates.Count) currencies fetched and sorted by value"
            }
        }
    }
    catch {
        return Err -Message "Crypto command failed: $_"
    }
}

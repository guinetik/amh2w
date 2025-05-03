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
                        $uri = "https://min-api.cryptocompare.com/data/price?fsym=$Symbol&tsyms=USD,EUR,CNY,JPY"
                        $data = (Invoke-WebRequest -Uri $uri -UseBasicParsing -UserAgent "curl").Content | ConvertFrom-Json
                        return [PSCustomObject]@{
                            Crypto        = "$Symbol ($Name)"
                            USD           = $data.USD
                            EUR           = $data.EUR
                            CNY           = $data.CNY
                            JPY           = $data.JPY
                        }
                    }
                    catch {
                        return [PSCustomObject]@{
                            Crypto = "$Symbol ($Name)"
                            USD    = "ERR"
                            EUR    = "ERR"
                            CNY    = "ERR"
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

                $rates = @()
                for ($i = 0; $i -lt $coins.Count; $i += 2) {
                    $rates += Get-CryptoRate $coins[$i] $coins[$i + 1]
                }

                Show-JsonTable $rates

                Write-Host "`n(by https://www.cryptocompare.com • Crypto is volatile and unregulated • Capital at risk • Taxes may apply)" -ForegroundColor DarkGray

                return Ok -Value $rates -Message "$($rates.Count) currencies fetched"
            }
        }
    }
    catch {
        return Err -Msg "Crypto command failed: $_"
    }
}

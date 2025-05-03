function rot13 {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Text
    )

    try {
        $rot13 = $Text.ToCharArray() | ForEach-Object {
            $code = [int]$_
            switch ($code) {
                { $_ -ge 65 -and $_ -le 90 } { [char](65 + (($_ - 65 + 13) % 26)) }  # A–Z
                { $_ -ge 97 -and $_ -le 122 } { [char](97 + (($_ - 97 + 13) % 26)) }  # a–z
                default { $_ }
            }
        }

        $encoded = -join $rot13
        Write-Host "🔁 ROT13:" -ForegroundColor Cyan
        Write-Host "   $encoded" -ForegroundColor Green

        return Ok -Value $encoded -Message "ROT13 applied"
    }
    catch {
        return Err -Msg "ROT13 failed: $_"
    }
}

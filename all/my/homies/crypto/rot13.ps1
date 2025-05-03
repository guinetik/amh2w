function rot13 {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("in", "out")]
        [string]$Direction,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]$Text
    )

    function rot13 {
        param([string]$InputText)
        return ($InputText.ToCharArray() | ForEach-Object {
            $code = [int]$_
            switch ($code) {
                { $_ -ge 65 -and $_ -le 90 } { [char](65 + (($_ - 65 + 13) % 26)) }  # A–Z
                { $_ -ge 97 -and $_ -le 122 } { [char](97 + (($_ - 97 + 13) % 26)) }  # a–z
                default { $_ }
            }
        }) -join ''
    }

    try {
        $rotated = rot13 -InputText $Text
        $label = if ($Direction -eq "in") { "Encoded" } else { "Decoded" }

        Write-Host "🔁 ROT13 $label`:" -ForegroundColor Cyan
        Write-Host "   $rotated" -ForegroundColor Green

        return Ok -Value $rotated -Message "ROT13 $label"
    }
    catch {
        return Err -Msg "ROT13 failed: $_"
    }
}

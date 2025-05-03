function anagrams {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Word,

        [Parameter(Position = 1)]
        [int]$Columns = 6
    )

    function Get-Permutations {
        param([string]$String)
        $Size = $String.Length
        $StringBuilder = New-Object System.Text.StringBuilder -ArgumentList $String
        $script:Permutations = @()
    
        function New-Anagram {
            param([int]$NewSize)
            if ($NewSize -eq 1) { return }
    
            for ($i = 0; $i -lt $NewSize; $i++) {
                New-Anagram -NewSize ($NewSize - 1)
                if ($NewSize -eq 2) {
                    $val = $StringBuilder.ToString()
                    if (-not $script:Permutations.Contains($val)) {
                        $script:Permutations += $val
                    }
                }
                Move-Left $NewSize
            }
        }
    
        function Move-Left {
            param([int]$NewSize)
            $pos = $Size - $NewSize
            $temp = $StringBuilder[$pos]
            for ($z = $pos + 1; $z -lt $Size; $z++) {
                $StringBuilder[$z - 1] = $StringBuilder[$z]
            }
            $StringBuilder[$Size - 1] = $temp
        }
    
        New-Anagram -NewSize $Size
        return $script:Permutations
    }

    try {
        $result = Get-Permutations $Word
        Write-Host "`n🔁 Anagrams for '$Word':" -ForegroundColor Cyan
        $result | Format-Wide -Column $Columns
        Write-Host ""
        Write-Host $result
        Write-Host ""
        return Ok -Value $result -Message "$($result.Count) anagrams generated"
    }
    catch {
        return Err -Msg "Anagram generation failed: $_"
    }
}

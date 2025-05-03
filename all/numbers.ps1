function ConvertTo-Binary([long]$value) { [Convert]::ToString($value, 2) }
function ConvertFrom-Binary([string]$value) { [Convert]::ToInt64($value, 2) }

function ConvertTo-Hex([long]$value) { [Convert]::ToString($value, 16) }
function ConvertFrom-Hex([string]$value) { [Convert]::ToInt64($value, 16) }

function ConvertTo-Octal([long]$value) { [Convert]::ToString($value, 8) }
function ConvertFrom-Octal([string]$value) { [Convert]::ToInt64($value, 8) }

function ConvertTo-Decimal([string]$value) { [int64]$value }
function ConvertFrom-Decimal([string]$value) { [int64]$value }

function ConvertTo-RomanNumeral([int]$number) {
    $map = @(
        @{val=1000; sym="M"}, @{val=900; sym="CM"}, @{val=500; sym="D"}, @{val=400; sym="CD"},
        @{val=100; sym="C"}, @{val=90; sym="XC"}, @{val=50; sym="L"}, @{val=40; sym="XL"},
        @{val=10; sym="X"}, @{val=9; sym="IX"}, @{val=5; sym="V"}, @{val=4; sym="IV"}, @{val=1; sym="I"}
    )
    $roman = ""
    foreach ($item in $map) {
        while ($number -ge $item.val) {
            $roman += $item.sym
            $number -= $item.val
        }
    }
    return $roman
}

function ConvertFrom-RomanNumeral([string]$roman) {
    $roman = $roman.ToUpper()
    $map = @{
        "M"=1000; "CM"=900; "D"=500; "CD"=400; "C"=100; "XC"=90;
        "L"=50; "XL"=40; "X"=10; "IX"=9; "V"=5; "IV"=4; "I"=1
    }
    $i = 0
    $num = 0
    while ($i -lt $roman.Length) {
        if ($i+1 -lt $roman.Length -and $map.ContainsKey($roman.Substring($i,2))) {
            $num += $map[$roman.Substring($i,2)]
            $i += 2
        } else {
            $num += $map[$roman.Substring($i,1)]
            $i++
        }
    }
    return $num
}

function ConvertTo-Base36([long]$value) {
    $alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    if ($value -eq 0) { return "0" }
    $result = ""
    while ($value -gt 0) {
        $result = $alphabet[$value % 36] + $result
        $value = [math]::Floor($value / 36)
    }
    return $result
}

function ConvertFrom-Base36([string]$str) {
    $str = $str.ToUpper()
    $alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $value = 0
    foreach ($char in $str.ToCharArray()) {
        $value = $value * 36 + $alphabet.IndexOf($char)
    }
    return $value
}

function ConvertTo-Radians([double]$degrees) {
    return ($degrees * [math]::PI / 180)
}

function ConvertFrom-Radians([double]$radians) {
    return ($radians * 180 / [math]::PI)
}

function numbers {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Number,

        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateSet("bin", "dec", "hex", "oct", "roman", "base36", "deg", "rad")]
        [string]$From,

        [Parameter(Position = 2, Mandatory = $true)]
        [ValidateSet("bin", "dec", "hex", "oct", "roman", "base36", "deg", "rad")]
        [string]$To
    )

    try {
        switch ($From) {
            "bin"     { $value = ConvertFrom-Binary $Number }
            "dec"     { $value = ConvertFrom-Decimal $Number }
            "hex"     { $value = ConvertFrom-Hex $Number }
            "oct"     { $value = ConvertFrom-Octal $Number }
            "roman"   { $value = ConvertFrom-RomanNumeral $Number }
            "base36"  { $value = ConvertFrom-Base36 $Number }
            "deg"     { $value = [double]$Number }
            "rad"     { $value = [double]$Number }
        }

        $converted = switch ($To) {
            "bin"     { ConvertTo-Binary $value }
            "dec"     { ConvertTo-Decimal $value }
            "hex"     { ConvertTo-Hex $value }
            "oct"     { ConvertTo-Octal $value }
            "roman"   { ConvertTo-RomanNumeral $value }
            "base36"  { ConvertTo-Base36 $value }
            "deg"     { ConvertFrom-Radians $value }
            "rad"     { ConvertTo-Radians $value }
        }

        $result = [PSCustomObject]@{
            Input        = "$Number"
            Output       = "$converted"
            DecimalValue = $value
        }

        Show-JsonTable @($result)
        return Ok -Value $result -Message "Conversion complete"
    }
    catch {
        return Err -Message "Conversion failed: $_"
    }
}

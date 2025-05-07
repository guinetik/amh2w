<#
.SYNOPSIS
Converts numbers between different numerical bases and notation systems.

.DESCRIPTION
Provides comprehensive number conversion functionality between various numerical systems,
including binary, decimal, hexadecimal, octal, roman numerals, base36, and angle units
(degrees/radians).

This module handles both forward and reverse conversions between all supported formats,
making it versatile for various mathematical, programming, and engineering applications.

.PARAMETER Number
The number to convert, specified as a string in the format indicated by the From parameter.

.PARAMETER From
The source format of the number. Valid values: bin, dec, hex, oct, roman, base36, deg, rad.

.PARAMETER To
The target format to convert to. Valid values: bin, dec, hex, oct, roman, base36, deg, rad.

.OUTPUTS
An Ok result object containing a PSCustomObject with the conversion details:
- Input: The original input number as a string
- Output: The converted number in the target format
- DecimalValue: The intermediate decimal value used for conversion

.EXAMPLE
all numbers 42 dec bin
# Converts decimal 42 to binary (101010)

.EXAMPLE
all numbers XIV roman dec
# Converts Roman numeral XIV to decimal (14)

.EXAMPLE
all numbers FF hex oct
# Converts hexadecimal FF to octal (377)

.EXAMPLE
all numbers 180 deg rad
# Converts 180 degrees to radians (3.14159...)

.NOTES
File: all/numbers.ps1
Command: all numbers

Supported conversion formats:
- bin: Binary (base 2)
- dec: Decimal (base 10)
- hex: Hexadecimal (base 16)
- oct: Octal (base 8)
- roman: Roman numerals
- base36: Base 36 (0-9, A-Z)
- deg: Degrees (angular measure)
- rad: Radians (angular measure)
#>
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
        return Ok $result "Conversion complete"
    }
    catch {
        return Err "Conversion failed: $_"
    }
}

<#
.SYNOPSIS
Converts an integer to its binary representation.

.PARAMETER value
The decimal integer to convert to binary.

.OUTPUTS
A string representing the binary form of the input value.
#>
function ConvertTo-Binary([long]$value) { [Convert]::ToString($value, 2) }

<#
.SYNOPSIS
Converts a binary string to its decimal integer value.

.PARAMETER value
The binary string to convert to decimal.

.OUTPUTS
A long integer representing the decimal value of the binary string.
#>
function ConvertFrom-Binary([string]$value) { [Convert]::ToInt64($value, 2) }

<#
.SYNOPSIS
Converts an integer to its hexadecimal representation.

.PARAMETER value
The decimal integer to convert to hexadecimal.

.OUTPUTS
A string representing the hexadecimal form of the input value.
#>
function ConvertTo-Hex([long]$value) { [Convert]::ToString($value, 16) }

<#
.SYNOPSIS
Converts a hexadecimal string to its decimal integer value.

.PARAMETER value
The hexadecimal string to convert to decimal.

.OUTPUTS
A long integer representing the decimal value of the hexadecimal string.
#>
function ConvertFrom-Hex([string]$value) { [Convert]::ToInt64($value, 16) }

<#
.SYNOPSIS
Converts an integer to its octal representation.

.PARAMETER value
The decimal integer to convert to octal.

.OUTPUTS
A string representing the octal form of the input value.
#>
function ConvertTo-Octal([long]$value) { [Convert]::ToString($value, 8) }

<#
.SYNOPSIS
Converts an octal string to its decimal integer value.

.PARAMETER value
The octal string to convert to decimal.

.OUTPUTS
A long integer representing the decimal value of the octal string.
#>
function ConvertFrom-Octal([string]$value) { [Convert]::ToInt64($value, 8) }

<#
.SYNOPSIS
Converts a string to a decimal integer value.

.PARAMETER value
The string to convert to a decimal integer.

.OUTPUTS
A long integer representing the decimal value of the input string.
#>
function ConvertTo-Decimal([string]$value) { [int64]$value }

<#
.SYNOPSIS
Converts a decimal value to a string representation.

.PARAMETER value
The decimal value to convert to a string.

.OUTPUTS
A string representing the input decimal value.
#>
function ConvertFrom-Decimal([string]$value) { [int64]$value }

<#
.SYNOPSIS
Converts an integer to its Roman numeral representation.

.PARAMETER number
The decimal integer to convert to Roman numerals.

.OUTPUTS
A string representing the Roman numeral form of the input value.

.NOTES
The algorithm uses a greedy approach to construct the Roman numeral, matching the
largest possible Roman numeral symbols first and working down to smaller ones.
#>
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

<#
.SYNOPSIS
Converts a Roman numeral to its decimal integer value.

.PARAMETER roman
The Roman numeral string to convert to decimal.

.OUTPUTS
An integer representing the decimal value of the Roman numeral.

.NOTES
This function handles both standard Roman numerals (I, V, X, L, C, D, M) and
subtractive combinations (IV, IX, XL, XC, CD, CM). Input is case-insensitive.
#>
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

<#
.SYNOPSIS
Converts an integer to its Base36 representation.

.PARAMETER value
The decimal integer to convert to Base36.

.OUTPUTS
A string representing the Base36 form of the input value, using digits 0-9 and letters A-Z.

.NOTES
Base36 is useful for creating compact, case-insensitive alphanumeric identifiers.
#>
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

<#
.SYNOPSIS
Converts a Base36 string to its decimal integer value.

.PARAMETER str
The Base36 string to convert to decimal. May contain digits 0-9 and letters A-Z (case-insensitive).

.OUTPUTS
A long integer representing the decimal value of the Base36 string.
#>
function ConvertFrom-Base36([string]$str) {
    $str = $str.ToUpper()
    $alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $value = 0
    foreach ($char in $str.ToCharArray()) {
        $value = $value * 36 + $alphabet.IndexOf($char)
    }
    return $value
}

<#
.SYNOPSIS
Converts an angle in degrees to radians.

.PARAMETER degrees
The angle in degrees to convert to radians.

.OUTPUTS
A double representing the angle in radians.
#>
function ConvertTo-Radians([double]$degrees) {
    return ($degrees * [math]::PI / 180)
}

<#
.SYNOPSIS
Converts an angle in radians to degrees.

.PARAMETER radians
The angle in radians to convert to degrees.

.OUTPUTS
A double representing the angle in degrees.
#>
function ConvertFrom-Radians([double]$radians) {
    return ($radians * 180 / [math]::PI)
}

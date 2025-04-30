function Ok {
    param($Value)
    return @{ ok = $true; value = $Value }
}

function Err {
    param(
        [string]$Msg,
        [bool]$Optional = $false
    )
    return @{ ok = $false; error = $Msg; optional = $Optional }
}

function IsOk {
    param($Result)
    return $Result.ok -eq $true
}

function Unwrap {
    param($Result)
    if ($Result.ok) {
        return $Result.value
    }
    Write-Host "Attempted to unwrap an error result: $($Result)" -ForegroundColor Red
    throw "Attempted to unwrap an error result: $($Result.error)"
}

function UnwrapOr {
    param(
        $Result,
        $Default
    )
    if ($Result.ok) {
        return $Result.value
    }
    return $Default
}

function Chain {
    param(
        $Result,
        [ScriptBlock]$Then
    )
    if ($Result.ok) {
        return & $Then $Result.value
    }
    return $Result # Pass through the error
}
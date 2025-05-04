# core/result.ps1
# Simple success/error result pattern for command chaining

function Ok {
    param($Value)
    return @{ ok = $true; value = $Value; message = $Message }
}

function Err {
    param($Message)
    return @{ ok = $false; error = $Message }
}

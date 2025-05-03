function path {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("addpath", "removepath", "addenv", "removeenv", "printpath", "printenv")]
        [string]$Action
    )

    switch ($Action) {
        "addpath" {
            $path = PromptInput "Enter the path to add to PATH"
            Add-PathEntry $path | ForEach-Object { Write-Host "✅ $_" -ForegroundColor Green }
        }
        "removepath" {
            $path = PromptInput "Enter the path to remove from PATH"
            Remove-PathEntry $path | ForEach-Object { Write-Host "✅ $_" -ForegroundColor Yellow }
        }
        "addenv" {
            $name = PromptInput "Enter variable name"
            $value = PromptInput "Enter value"
            Add-EnvVar $name $value | ForEach-Object { Write-Host "✅ $_" -ForegroundColor Green }
        }
        "removeenv" {
            $name = PromptInput "Enter variable name to remove"
            Remove-EnvVar $name | ForEach-Object { Write-Host "✅ $_" -ForegroundColor Yellow }
        }
        "printpath" { Print-PathTable }
        "printenv" { Print-EnvTable }
    }
}

function Add-PathEntry {
    param([string]$PathToAdd)
    $results = @()
    $results += Set-PathEntry "User" $PathToAdd
    if (Test-IsAdmin) { $results += Set-PathEntry "Machine" $PathToAdd }
    return $results
}

function Remove-PathEntry {
    param([string]$PathToRemove)
    $results = @()
    $results += Set-PathEntry "User" $PathToRemove $true
    if (Test-IsAdmin) { $results += Set-PathEntry "Machine" $PathToRemove $true }
    return $results
}

function Set-PathEntry {
    param([string]$Scope, [string]$Value, [switch]$Remove)
    $reg = if ($Scope -eq "User") { "HKCU:\Environment" } else { "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" }
    $path = (Get-ItemProperty -Path $reg -Name Path -ErrorAction SilentlyContinue).Path
    $parts = ($path -split ";") -ne ""
    $newPath = if ($Remove) {
        ($parts | Where-Object { $_ -ne $Value }) -join ";"
    } elseif ($parts -contains $Value) {
        return "$Value already in $Scope PATH"
    } else {
        ($parts + $Value) -join ";"
    }
    Set-ItemProperty -Path $reg -Name Path -Value $newPath
    return "$Scope PATH updated"
}

function Add-EnvVar {
    param([string]$Name, [string]$Value)
    $results = @()
    $results += Set-EnvVar "User" $Name $Value
    if (Test-IsAdmin) { $results += Set-EnvVar "Machine" $Name $Value }
    return $results
}

function Remove-EnvVar {
    param([string]$Name)
    $results = @()
    $results += Set-EnvVar "User" $Name $null $true
    if (Test-IsAdmin) { $results += Set-EnvVar "Machine" $Name $null $true }
    return $results
}

function Set-EnvVar {
    param([string]$Scope, [string]$Name, [string]$Value, [switch]$Remove)
    $reg = if ($Scope -eq "User") { "HKCU:\Environment" } else { "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" }
    if ($Remove) {
        Remove-ItemProperty -Path $reg -Name $Name -ErrorAction SilentlyContinue
        return "$Scope variable '$Name' removed"
    } else {
        Set-ItemProperty -Path $reg -Name $Name -Value $Value
        return "$Scope variable '$Name' set to '$Value'"
    }
}

function Print-PathTable {
    $user = (Get-ItemProperty -Path "HKCU:\Environment" -Name Path -ErrorAction SilentlyContinue).Path
    $machine = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name Path -ErrorAction SilentlyContinue).Path

    Write-Host "`n👤 User PATH" -ForegroundColor Cyan
    $userJson = ($user -split ';' | Where-Object { $_ -ne '' }) | ForEach-Object { [PSCustomObject]@{ Entry = $_ } }
    Show-JsonTable $userJson

    Write-Host "`n🖥️ Machine PATH" -ForegroundColor Cyan
    $machineJson = ($machine -split ';' | Where-Object { $_ -ne '' }) | ForEach-Object { [PSCustomObject]@{ Entry = $_ } }
    Show-JsonTable $machineJson
}

function Print-EnvTable {
    $json = @()
    $userVars = Get-ItemProperty -Path "HKCU:\Environment"
    $machineVars = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"

    $userVars.PSObject.Properties | ForEach-Object {
        $json += [PSCustomObject]@{ Scope = "User"; Name = $_.Name; Value = $_.Value }
    }

    $machineVars.PSObject.Properties | ForEach-Object {
        $json += [PSCustomObject]@{ Scope = "Machine"; Name = $_.Name; Value = $_.Value }
    }

    Show-JsonTable $json
}

function PromptInput($label) {
    return Read-Host "$label"
}
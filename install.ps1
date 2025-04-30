<#  
    setup.ps1  
    Installs AMH2W as a proper PowerShell module,  
    copying your entire core\ and all\ folder trees.  
#>

[CmdletBinding()]
param(
    [switch]$CreateProfileEntry = $true,
    [string] $InstallPath = "$HOME\Documents\WindowsPowerShell\Modules\AMH2W"
)

$ErrorActionPreference = 'Stop'
$ScriptPath           = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`nInstalling AMH2W module to $InstallPath`n" -ForegroundColor Cyan

# 1) Create base module folders
$folders = @(
    $InstallPath,
    "$InstallPath\core",
    "$InstallPath\all"
)
foreach ($f in $folders) {
    if (-not (Test-Path $f)) {
        New-Item -ItemType Directory -Path $f -Force | Out-Null
    }
}

# 2) Recursively copy core\ → $InstallPath\core
Write-Host "Copying core\ tree…" -ForegroundColor Cyan
Copy-Item -Path "$ScriptPath\core\*" `
          -Destination "$InstallPath\core" `
          -Recurse -Force

# 3) Recursively copy all\ → $InstallPath\all
Write-Host "Copying all\ tree…" -ForegroundColor Cyan
Copy-Item -Path "$ScriptPath\all\*" `
          -Destination "$InstallPath\all" `
          -Recurse -Force

# 4) Copy module entrypoint
Write-Host "Copying AMH2W.psm1" -ForegroundColor Cyan
Copy-Item -Path "$ScriptPath\AMH2W.psm1" `
          -Destination "$InstallPath\AMH2W.psm1" `
          -Force

# 5) Generate module manifest
$manifest = Join-Path $InstallPath 'AMH2W.psd1'
Write-Host "Writing manifest: $manifest" -ForegroundColor Cyan
New-ModuleManifest -Path $manifest `
    -RootModule 'AMH2W.psm1' `
    -ModuleVersion '0.1.0' `
    -Author 'Your Name' `
    -Description 'AMH2W PowerShell Utility Module' `
    -PowerShellVersion '5.1' `
    -FunctionsToExport '*' `
    -AliasesToExport '*' `
    -VariablesToExport '*' `
    -NestedModules @()

# 6) Optionally auto-import on profile load
if ($CreateProfileEntry) {
    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }
    $importLine = 'Import-Module AMH2W'
    if ((Get-Content $PROFILE) -notcontains $importLine) {
        Add-Content -Path $PROFILE -Value "`n# Auto-load AMH2W`n$importLine"
    }
}

Write-Host "`n🎉 Installation complete! Restart PowerShell" -ForegroundColor Green

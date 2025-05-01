# install.ps1
# Simple installer script for AMH2W module

[CmdletBinding()]
param(
    [string]$InstallPath = "$HOME\Documents\WindowsPowerShell\Modules\AMH2W"
)

$ErrorActionPreference = 'Stop'
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Installing AMH2W module to $InstallPath" -ForegroundColor Cyan

# Create module folder structure
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

# Create core folder
$coreFolder = Join-Path $InstallPath "core"
if (-not (Test-Path $coreFolder)) {
    New-Item -ItemType Directory -Path $coreFolder -Force | Out-Null
}

# Copy core files
Get-ChildItem -Path "$ScriptPath\core" -Filter "*.ps1" | ForEach-Object {
    $destFile = Join-Path $coreFolder $_.Name
    Copy-Item -Path $_.FullName -Destination $destFile -Force
    Write-Host "  Copied core file: $($_.Name)" -ForegroundColor DarkGray
}

# Create command hierarchy
$allFolder = Join-Path $InstallPath "all"
if (-not (Test-Path $allFolder)) {
    New-Item -ItemType Directory -Path $allFolder -Force | Out-Null
}

# Mirror the namespace hierarchy
Get-ChildItem -Path "$ScriptPath\all" -Directory -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring("$ScriptPath\all".Length)
    $targetPath = Join-Path $allFolder $relativePath
    
    if (-not (Test-Path $targetPath)) {
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        Write-Host "  Created folder: $targetPath" -ForegroundColor DarkGray
    }
}

# Copy all PS1 files
Get-ChildItem -Path "$ScriptPath\all" -Filter "*.ps1" -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring("$ScriptPath\all".Length)
    $targetFile = Join-Path $allFolder $relativePath
    
    Copy-Item -Path $_.FullName -Destination $targetFile -Force
    Write-Host "  Copied command file: $relativePath" -ForegroundColor DarkGray
}

# Copy module entrypoint
Copy-Item -Path "$ScriptPath\AMH2W.psm1" -Destination "$InstallPath\AMH2W.psm1" -Force
Write-Host "  Copied module entry point: AMH2W.psm1" -ForegroundColor DarkGray

# Create module manifest
$manifestPath = Join-Path $InstallPath "AMH2W.psd1"
New-ModuleManifest -Path $manifestPath `
    -RootModule "AMH2W.psm1" `
    -ModuleVersion "0.1.0" `
    -Author "AMH2W Contributors" `
    -Description "All My Homies Handle Windows - PowerShell utility library" `
    -PowerShellVersion "5.1" `
    -FunctionsToExport @("all", "🤓")

Write-Host "`nInstallation complete." -ForegroundColor Green
Write-Host "To use the module, restart PowerShell or run: " -NoNewline
Write-Host "Import-Module AMH2W -Force" -ForegroundColor Yellow

Write-Host "`nTry these commands:" -ForegroundColor Cyan
Write-Host "  all" -ForegroundColor White
Write-Host "  all my" -ForegroundColor White
Write-Host "  all my homies" -ForegroundColor White
Write-Host "  all my homies hate" -ForegroundColor White
Write-Host "  all my homies hate windows" -ForegroundColor White
Write-Host "  all my homies hate windows version" -ForegroundColor White

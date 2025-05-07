$Repo = "guinetik/amh2w"
$Asset = "release.zip"

if ($args.Count -ge 1) { $Repo = $args[0] }
if ($args.Count -ge 2) { $Asset = $args[1] }

Write-Host "🚀 Starting AMH2W installation..." -ForegroundColor Cyan
# Construct the download URL
$downloadUrl = "https://github.com/$Repo/releases/latest/download/$Asset"

# Create a temp folder
$tempDir = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString())
$zipPath = Join-Path $tempDir "release.zip"

Write-Host "⬇️  Downloading latest release from $downloadUrl..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

Write-Host "📦 Extracting ZIP to $tempDir..." -ForegroundColor Yellow
Expand-Archive -Path $zipPath -DestinationPath $tempDir

# Find install.ps1 in the extracted folder
$installScript = Get-ChildItem -Path $tempDir -Recurse -Filter install.ps1 | Select-Object -First 1
if (-not $installScript) {
    Write-Host "❌ install.ps1 not found in the extracted release. Aborting installation." -ForegroundColor Red
    exit 1
}

Write-Host "⚡ Running installer: $($installScript.FullName)" -ForegroundColor Cyan
# Detect PowerShell edition and use the correct executable
if ($PSVersionTable.PSEdition -eq 'Core') {
    $psExe = 'pwsh'
} else {
    $psExe = 'powershell'
}
# Run the install script
Start-Process $psExe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $installScript.FullName -Wait

# Optional: Clean up
Write-Host "🧹 Cleaning up temporary files..." -ForegroundColor DarkGray
Get-Content $zipPath | Out-Null  # Ensure file is not locked
Remove-Item -Recurse -Force $tempDir

Write-Host "✅ Module installed!" -ForegroundColor Green

# Add AMH2W module import to the user's profile if not already present
$profilePath = $PROFILE
$importLine = "Import-Module AMH2W"

Write-Host "🔍 Checking your PowerShell profile..." -ForegroundColor Cyan
if (-not (Test-Path $profilePath)) {
    Write-Host "📄 Profile not found. Creating new profile at: $profilePath" -ForegroundColor Yellow
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$profileContent = Get-Content $profilePath -Raw
if ($profileContent -notmatch [regex]::Escape($importLine)) {
    Add-Content -Path $profilePath -Value "`n$importLine"
    Write-Host "✨ Added AMH2W module import to your profile!" -ForegroundColor Green
    Write-Host "➡️  Next time you open PowerShell, AMH2W will be ready to use! 🚀" -ForegroundColor Green
    Write-Host "   Profile updated: $profilePath" -ForegroundColor DarkGray
} else {
    Write-Host "✅ AMH2W module import already present in your profile. No changes made." -ForegroundColor Green
}

Write-Host "🎉 All done! Enjoy using AMH2W! 🤓" -ForegroundColor Cyan
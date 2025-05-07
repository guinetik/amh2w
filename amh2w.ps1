# Set your GitHub repo and asset name here
$repo = "guinetik/amh2w"
$asset = "release.zip"

# Construct the download URL
$downloadUrl = "https://github.com/$repo/releases/latest/download/$asset"

# Create a temp folder
$tempDir = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString())
$zipPath = Join-Path $tempDir "release.zip"

Write-Host "Downloading latest release from $downloadUrl..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

Write-Host "Extracting ZIP to $tempDir..."
Expand-Archive -Path $zipPath -DestinationPath $tempDir

# Find install.ps1 in the extracted folder
$installScript = Get-ChildItem -Path $tempDir -Recurse -Filter install.ps1 | Select-Object -First 1
if (-not $installScript) {
    Write-Error "install.ps1 not found in the extracted release."
    exit 1
}

Write-Host "Running $($installScript.FullName)..."
# Detect PowerShell edition and use the correct executable
if ($PSVersionTable.PSEdition -eq 'Core') {
    $psExe = 'pwsh'
} else {
    $psExe = 'powershell'
}
# Run the install script
Start-Process $psExe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $installScript.FullName -Wait

# Optional: Clean up
Get-Content $zipPath | Out-Null  # Ensure file is not locked
Remove-Item -Recurse -Force $tempDir

Write-Host "Done."
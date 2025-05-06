function bootstrap {
    param(
        [string]$PackageFile = "$PSScriptRoot\packages.json",
        [object]$Yolo = $false
    )

    $Yolo = Truthy $Yolo

    # Elevate if not admin
    if (-not (Test-IsAdmin)) {
        Log-Warning "This operation requires elevation."
        $cmd = "all my homies bootstrap `"$PackageFile`" $Yolo"
        Invoke-Elevate -Command $cmd -Prompt $true -Description "Installing software from list"
        return Ok "Elevated script execution launched."
    }

    if (-not (Test-Path $PackageFile)) {
        return Err "Package file not found: $PackageFile"
    }

    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        return Err "Chocolatey is required but not installed. Run: all my homies install choco"
    }

    try {
        $json = Get-Content $PackageFile -Raw | ConvertFrom-Json
    } catch {
        return Err "Failed to parse JSON: $_"
    }

    $packages = @()
    foreach ($category in $json.PSObject.Properties) {
        $packages += $category.Value | ForEach-Object {
            [PSCustomObject]@{
                Category    = $category.Name
                Name        = $_.name
                Description = $_.description
                Command     = $_.command
            }
        }
    }

    if ($packages.Count -eq 0) {
        return Err "No commands found in JSON file."
    }

    function Install-Package {
        param(
            [string]$Command,
            [string]$Name,
            [string]$Description,
            [bool]$Yolo = $false
        )

        process {
            Write-Host "📦 [$Name] $Description"
            if (-not $Yolo) {
                $choice = Get-SelectionFromUser -Options @('Install', 'Skip') -Prompt "Run: $Command ?"
                if ($choice -ne 'Install') {
                    return Ok "⏭️ Skipped: $Name"
                }
            }

            try {
                Write-Host "Running: $Command"
                $exitCode = Invoke-VerboseCommand $Command
                if ($exitCode -ne 0) {
                    throw "Command failed with exit code $exitCode"
                }
                return Ok "✅ $Name installed successfully"
            } catch {
                return Err "❌ $Name failed: $_" -Optional $true
            }
        }
    }

    Write-Host "Starting Package Installer with $($packages.Count) items"
    $results = @()
    $success = $true

    for ($i = 0; $i -lt $packages.Count; $i++) {
        $pkg = $packages[$i]
        Log-Info "Processing [$($pkg.Category)] $($pkg.Name) ($($i+1)/$($packages.Count))"

        $result = Install-Package -Command $pkg.Command -Name $pkg.Name -Description $pkg.Description -Yolo:$Yolo
        $results += $result

        if ($result.Type -eq "Err" -and -not $result.Optional) {
            $success = $false
            break
        }
    }

    if ($success) {
        return Ok "🎉 All packages installed successfully" -Value $results
    } else {
        return Err "💥 Installation failed at some point" -Value $results
    }
}

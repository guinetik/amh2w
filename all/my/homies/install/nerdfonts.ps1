function nerdfonts {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("list", "install", "search", "info")]
        [string]$Action = "list",
        
        [Parameter(Position = 1)]
        [string]$FontName = "",
        
        [Parameter(Position = 2)]
        [switch]$ForceRefresh = $false,
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    try {
        # Cache configuration
        $cacheDir = "$env:LOCALAPPDATA\AMH2W\Cache"
        $cacheFile = Join-Path $cacheDir "nerdfonts-release.json"
        $cacheTimeout = [timespan]::FromHours(24)
        
        # Ensure cache directory exists
        if (-not (Test-Path $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }

        # Check cache validity
        $useCache = $false
        if ((Test-Path $cacheFile) -and -not $ForceRefresh) {
            $cacheAge = (Get-Date) - (Get-Item $cacheFile).LastWriteTime
            if ($cacheAge -lt $cacheTimeout) {
                $useCache = $true
            }
        }

        # Get release info
        $releaseInfo = $null
        if ($useCache) {
            Log-Info "Using cached release information"
            $releaseInfo = Get-Content $cacheFile -Raw | ConvertFrom-Json
        } else {
            Log-Info "Fetching latest release information from GitHub..."
            
            # Use the homies hate fetch utility
            $fetchResult = fetch -Url "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" -NoPrint
            
            if ($fetchResult.ok) {
                $releaseInfo = $fetchResult.Value.ContentObject
                
                # Cache the result
                $releaseInfo | ConvertTo-Json -Depth 10 | Set-Content $cacheFile
                Log-Info "Release information cached successfully"
            } else {
                Log-Error "Failed to fetch release information"
                return $fetchResult
            }
        }

        switch ($Action) {
            "list" {
                return List-NerdFonts -ReleaseInfo $releaseInfo
            }
            
            "search" {
                if ([string]::IsNullOrWhiteSpace($FontName)) {
                    Log-Error "Please provide a search term"
                    return Err "Search term required"
                }
                return Search-NerdFonts -ReleaseInfo $releaseInfo -SearchTerm $FontName
            }
            
            "install" {
                if ([string]::IsNullOrWhiteSpace($FontName)) {
                    Log-Error "Please provide a font name to install"
                    return Err "Font name required for installation"
                }
                return Install-NerdFont -ReleaseInfo $releaseInfo -FontName $FontName
            }
            
            "info" {
                if ([string]::IsNullOrWhiteSpace($FontName)) {
                    return Show-ReleaseInfo -ReleaseInfo $releaseInfo
                } else {
                    return Show-FontInfo -ReleaseInfo $releaseInfo -FontName $FontName
                }
            }
            
            default {
                Log-Error "Unknown action: $Action"
                return Err "Invalid action. Use: list, search, install, or info"
            }
        }
    }
    catch {
        Log-Error "Failed to execute nerdfonts command: $_"
        return Err $_
    }
}

function List-NerdFonts {
    param(
        [Parameter(Mandatory)]
        $ReleaseInfo
    )

    try {
        $fonts = $ReleaseInfo.assets | Where-Object { 
            $_.name -match '\.zip$' -and $_.name -notmatch 'NerdFontsSymbolsOnly' 
        } | ForEach-Object { 
            [PSCustomObject]@{
                Name = $_.name -replace '\.zip$', ''
                Size = Format-ByteSize -Bytes $_.size
                DownloadUrl = $_.browser_download_url
            }
        }

        Write-Host "`nAvailable Nerd Fonts (v$($ReleaseInfo.tag_name)):" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Cyan
        
        foreach ($font in $fonts | Sort-Object Name) {
            Write-Host "$($font.Name)" -ForegroundColor Green -NoNewline
            Write-Host " ($($font.Size))" -ForegroundColor DarkGray
        }
        
        Write-Host "`nTotal: $($fonts.Count) fonts available" -ForegroundColor Cyan
        Write-Host "Use 'all my homies install nerdfonts install <FontName>' to install a font" -ForegroundColor Yellow
        
        return Ok $fonts
    }
    catch {
        Log-Error "Failed to list fonts: $_"
        return Err $_
    }
}

function Search-NerdFonts {
    param(
        [Parameter(Mandatory)]
        $ReleaseInfo,
        
        [Parameter(Mandatory)]
        [string]$SearchTerm
    )

    try {
        $fonts = $ReleaseInfo.assets | Where-Object { 
            $_.name -match '\.zip$' -and $_.name -notmatch 'NerdFontsSymbolsOnly' 
        } | ForEach-Object { 
            [PSCustomObject]@{
                Name = $_.name -replace '\.zip$', ''
                Size = Format-ByteSize -Bytes $_.size
                DownloadUrl = $_.browser_download_url
            }
        }

        $matchedFonts = $fonts | Where-Object { $_.Name -like "*$SearchTerm*" }

        if ($matchedFonts.Count -eq 0) {
            Write-Host "`nNo fonts found matching '$SearchTerm'" -ForegroundColor Yellow
            Write-Host "Try 'all my homies install nerdfonts list' to see all available fonts" -ForegroundColor DarkGray
            return Ok @()
        }

        Write-Host "`nFonts matching '$SearchTerm':" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Cyan
        
        foreach ($font in $matchedFonts | Sort-Object Name) {
            Write-Host "$($font.Name)" -ForegroundColor Green -NoNewline
            Write-Host " ($($font.Size))" -ForegroundColor DarkGray
        }
        
        Write-Host "`nFound: $($matchedFonts.Count) matching fonts" -ForegroundColor Cyan
        
        return Ok $matchedFonts
    }
    catch {
        Log-Error "Failed to search fonts: $_"
        return Err $_
    }
}

function Install-NerdFont {
    param(
        [Parameter(Mandatory)]
        $ReleaseInfo,
        
        [Parameter(Mandatory)]
        [string]$FontName
    )

    try {
        # Check if running as admin
        if (-not (Test-IsAdmin)) {
            Log-Warning "Font installation requires administrator privileges"
            
            # Construct the original command to elevate
            $originalCommand = "all my homies install nerdfonts install `"$FontName`""
            
            # Elevate with prompt and keep the window open
            Invoke-Elevate -Command $originalCommand -Prompt $true -Description "Font installation requires administrator privileges to modify system fonts" -KeepOpen $true
            
            return Ok "Elevation requested"
        }

        # Find the font in the release assets
        $fontAsset = $ReleaseInfo.assets | Where-Object { 
            $_.name -eq "$FontName.zip" 
        } | Select-Object -First 1

        if (-not $fontAsset) {
            # Try case-insensitive search
            $fontAsset = $ReleaseInfo.assets | Where-Object { 
                $_.name -eq "$FontName.zip" -or $_.name -like "*$FontName*.zip"
            } | Select-Object -First 1
            
            if (-not $fontAsset) {
                Log-Error "Font '$FontName' not found"
                Write-Host "Use 'all my homies install nerdfonts list' to see available fonts" -ForegroundColor Yellow
                return Err "Font not found"
            }
        }

        # Check if font is already installed
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
        
        # Extract the font name without .zip
        $fontBaseName = $fontAsset.name -replace '\.zip$', ''
        
        # Common pattern for nerd font display names
        $expectedDisplayNames = @(
            "$fontBaseName NF",
            "$fontBaseName Nerd Font",
            "$fontBaseName",
            ($fontBaseName -replace 'NerdFont', '') + "Nerd Font"
        )
        
        $isInstalled = $false
        foreach ($displayName in $expectedDisplayNames) {
            if ($fontFamilies -contains $displayName) {
                $isInstalled = $true
                Log-Info "Font '$displayName' is already installed"
                break
            }
        }
        
        if ($isInstalled) {
            return Ok "Font already installed"
        }

        # Download and install the font
        Log-Info "Downloading $fontBaseName..."
        $zipFilePath = "$env:TEMP\$($fontAsset.name)"
        $extractPath = "$env:TEMP\$fontBaseName"

        # Use the homies hate fetch utility to download
        $scriptPath = Join-Path $PSScriptRoot "..\hate\fetch.ps1"
        . $scriptPath
        
        $downloadResult = fetch -Url $fontAsset.browser_download_url -OutFile $zipFilePath
        
        if (-not $downloadResult.ok) {
            Log-Error "Failed to download font"
            return $downloadResult
        }

        Log-Info "Extracting font files..."
        try {
            Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
        }
        catch {
            Log-Error "Failed to extract font files: $_"
            return Err "Extraction failed: $_"
        }
        
        Log-Info "Installing fonts..."
        $installedCount = 0
        try {
            $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
            Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
                If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                    $destination.CopyHere($_.FullName, 0x10)
                    $installedCount++
                    Log-Debug "Installed: $($_.Name)"
                }
            }
            
            Get-ChildItem -Path $extractPath -Recurse -Filter "*.otf" | ForEach-Object {
                If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                    $destination.CopyHere($_.FullName, 0x10)
                    $installedCount++
                    Log-Debug "Installed: $($_.Name)"
                }
            }
        }
        catch {
            Log-Error "Failed to install fonts: $_"
            return Err "Installation failed: $_"
        }

        # Cleanup
        try {
            Log-Info "Cleaning up temporary files..."
            Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $zipFilePath -Force -ErrorAction SilentlyContinue
        }
        catch {
            Log-Warning "Failed to clean up temporary files: $_"
        }
        
        if ($installedCount -gt 0) {
            Log-Success "Successfully installed $installedCount font files for $fontBaseName"
            return Ok "Font $fontBaseName installed successfully"
        }
        else {
            Log-Warning "No new font files were installed (they may already exist)"
            return Ok "No new fonts installed"
        }
    }
    catch {
        Log-Error "Failed to install font: $_"
        return Err $_
    }
}

function Show-ReleaseInfo {
    param(
        [Parameter(Mandatory)]
        $ReleaseInfo
    )

    Write-Host "`nNerd Fonts Release Information:" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Version: " -NoNewline -ForegroundColor Green
    Write-Host $ReleaseInfo.tag_name
    Write-Host "Released: " -NoNewline -ForegroundColor Green
    Write-Host ([DateTime]::Parse($ReleaseInfo.published_at).ToString("yyyy-MM-dd HH:mm:ss"))
    Write-Host "Total Assets: " -NoNewline -ForegroundColor Green
    Write-Host $ReleaseInfo.assets.Count
    
    $fontAssets = $ReleaseInfo.assets | Where-Object { $_.name -match '\.zip$' }
    Write-Host "Font Files: " -NoNewline -ForegroundColor Green
    Write-Host $fontAssets.Count

    return Ok $ReleaseInfo
}

function Show-FontInfo {
    param(
        [Parameter(Mandatory)]
        $ReleaseInfo,
        
        [Parameter(Mandatory)]
        [string]$FontName
    )

    $fontAsset = $ReleaseInfo.assets | Where-Object { 
        $_.name -eq "$FontName.zip" -or $_.name -like "*$FontName*.zip"
    } | Select-Object -First 1

    if (-not $fontAsset) {
        Log-Error "Font '$FontName' not found"
        return Err "Font not found"
    }

    Write-Host "`nNerd Font Information:" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Name: " -NoNewline -ForegroundColor Green
    Write-Host ($fontAsset.name -replace '\.zip$', '')
    Write-Host "Size: " -NoNewline -ForegroundColor Green
    Write-Host (Format-ByteSize -Bytes $fontAsset.size)
    Write-Host "Download Count: " -NoNewline -ForegroundColor Green
    Write-Host $fontAsset.download_count
    Write-Host "Content Type: " -NoNewline -ForegroundColor Green
    Write-Host $fontAsset.content_type
    Write-Host "Created: " -NoNewline -ForegroundColor Green
    Write-Host ([DateTime]::Parse($fontAsset.created_at).ToString("yyyy-MM-dd HH:mm:ss"))

    return Ok $fontAsset
}

function Format-ByteSize {
    param(
        [long]$Bytes
    )
    
    if ($Bytes -ge 1GB) {
        return "{0:0.00} GB" -f ($Bytes / 1GB)
    }
    elseif ($Bytes -ge 1MB) {
        return "{0:0.00} MB" -f ($Bytes / 1MB)
    }
    elseif ($Bytes -ge 1KB) {
        return "{0:0.00} KB" -f ($Bytes / 1KB)
    }
    else {
        return "$Bytes bytes"
    }
}

# Export the function
Export-ModuleMember -Function nerdfonts

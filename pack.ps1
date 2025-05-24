# pack.ps1
# Creates a distribution package for AMH2W module

[CmdletBinding()]
param(
    [string]$Version = "0.1.0",
    [string]$OutputPath = ".",
    [switch]$Force = $false
)

$ErrorActionPreference = 'Stop'
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define what to exclude from the package
$ExcludeItems = @(
    "test",                 # Test folder
    "tests",                # Alternative test folder name
    "docs",                 # Documentation folder
    "build.ps1",           # Build script
    "merge.ps1",           # Merge script
    "pack.ps1",            # This pack script itself
    "*.md",                # All markdown files
    ".git",                # Git folder
    ".vscode",             # VS Code settings
    "*.zip",               # Any existing zip files
    "release",             # Release folder if it exists
    "temp_pack"            # Temporary packing folder
    ".gitignore"
    "fix-encoding.ps1"
    "LICENSE"
)

Write-Host "🚀 AMH2W Release Packager" -ForegroundColor Cyan
Write-Host "Version: $Version" -ForegroundColor Yellow
Write-Host ""

# Create output file name
$zipFileName = "release.zip"
$zipFilePath = Join-Path (Resolve-Path $OutputPath) $zipFileName

# Check if output file already exists
if ((Test-Path $zipFilePath) -and -not $Force) {
    Write-Host "❌ Release package already exists: $zipFilePath" -ForegroundColor Red
    Write-Host "Use -Force to overwrite" -ForegroundColor Yellow
    exit 1
}

# Create temporary packing directory
$tempDir = Join-Path $ScriptPath "temp_pack"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    Write-Host "📦 Preparing package contents..." -ForegroundColor Green
    
    # Get all items in the root directory
    $allItems = Get-ChildItem -Path $ScriptPath -Force
    
    # Filter out excluded items
    $includedItems = $allItems | Where-Object {
        $item = $_
        $shouldExclude = $false
        
        foreach ($exclude in $ExcludeItems) {
            if ($exclude.Contains("*")) {
                # Handle wildcards
                if ($item.Name -like $exclude) {
                    $shouldExclude = $true
                    break
                }
            } else {
                # Handle exact matches
                if ($item.Name -eq $exclude) {
                    $shouldExclude = $true
                    break
                }
            }
        }
        
        return -not $shouldExclude
    }
    
    # Copy included items to temp directory
    Write-Host "📁 Including files and folders:" -ForegroundColor Yellow
    foreach ($item in $includedItems) {
        $destPath = Join-Path $tempDir $item.Name
        
        if ($item.PSIsContainer) {
            Copy-Item -Path $item.FullName -Destination $destPath -Recurse -Force
            Write-Host "  📂 $($item.Name)/" -ForegroundColor Cyan
        } else {
            Copy-Item -Path $item.FullName -Destination $destPath -Force
            Write-Host "  📄 $($item.Name)" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "🚫 Excluded items:" -ForegroundColor Red
    $allItems | Where-Object {
        $item = $_
        $shouldExclude = $false
        
        foreach ($exclude in $ExcludeItems) {
            if ($exclude.Contains("*")) {
                if ($item.Name -like $exclude) {
                    $shouldExclude = $true
                    break
                }
            } else {
                if ($item.Name -eq $exclude) {
                    $shouldExclude = $true
                    break
                }
            }
        }
        
        return $shouldExclude
    } | ForEach-Object {
        if ($_.PSIsContainer) {
            Write-Host "  📂 $($_.Name)/" -ForegroundColor DarkRed
        } else {
            Write-Host "  📄 $($_.Name)" -ForegroundColor DarkRed
        }
    }
    
    Write-Host ""
    Write-Host "🗜️  Creating release package..." -ForegroundColor Green
    
    # Create the ZIP file
    if (Test-Path $zipFilePath) {
        Remove-Item $zipFilePath -Force
    }
    
    # Use Compress-Archive to create the ZIP
    Compress-Archive -Path "$tempDir\*" -DestinationPath $zipFilePath -Force
    
    # Get file size for display
    $zipFile = Get-Item $zipFilePath
    $fileSizeMB = [math]::Round($zipFile.Length / 1MB, 2)
    
    Write-Host ""
    Write-Host "✅ Release package created successfully!" -ForegroundColor Green
    Write-Host "📦 Package: $zipFileName" -ForegroundColor Cyan
    Write-Host "📍 Location: $zipFilePath" -ForegroundColor Yellow
    Write-Host "📏 Size: $fileSizeMB MB" -ForegroundColor White
    Write-Host ""
    Write-Host "🚀 Ready for GitHub release!" -ForegroundColor Magenta
    
    # Show package contents summary
    $packagedItems = Get-ChildItem -Path $tempDir
    Write-Host ""
    Write-Host "📋 Package contents summary:" -ForegroundColor Yellow
    Write-Host "  Files: $($packagedItems | Where-Object { -not $_.PSIsContainer } | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor White
    Write-Host "  Folders: $($packagedItems | Where-Object { $_.PSIsContainer } | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor White
    
    # List main folders included
    $mainFolders = $packagedItems | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty Name
    if ($mainFolders.Count -gt 0) {
        Write-Host "  Main folders: $($mainFolders -join ', ')" -ForegroundColor Cyan
    }
    
} finally {
    # Clean up temporary directory
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
        Write-Host ""
        Write-Host "🧹 Cleaned up temporary files" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "💡 Usage instructions:" -ForegroundColor Yellow
Write-Host "  1. Upload $zipFileName to GitHub releases" -ForegroundColor White
Write-Host "  2. Users can download and extract" -ForegroundColor White
Write-Host "  3. Run: .\install.ps1 to install the module" -ForegroundColor White 
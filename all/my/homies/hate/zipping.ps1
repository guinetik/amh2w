# all/my/homies/hate/zipping.ps1
# File compression and decompression utility
# Supports zip, gzip, tar.gz, and rar formats
# Prioritizes 7-Zip or WinRAR when available, falls back to Windows built-in commands

function zipping {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("zip", "unzip")]
        [string] $Action,

        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [object[]] $Rest
    )

    try {
        $result = switch ($Action) {
            "zip" {
                $source = if ($Rest.Count -ge 1) { $Rest[0] } else { Read-Host "Enter source file/folder to compress" }
                $destination = if ($Rest.Count -ge 2) { $Rest[1] } else { $null }
                $format = if ($Rest.Count -ge 3) { $Rest[2] } else { "zip" }
                
                Compress-Item -Source $source -Destination $destination -Format $format
            }
    
            "unzip" {
                $source = if ($Rest.Count -ge 1) { $Rest[0] } else { Read-Host "Enter archive file to extract" }
                $destination = if ($Rest.Count -ge 2) { $Rest[1] } else { $null }
                
                Expand-Item -Source $source -Destination $destination
            }
        }
        return $result
    } catch {
        Log-Error "❌ Error: $_"
        return Err "Error: $_"
    }
}

# Check for available compression tools
function Get-AvailableTools {
    $tools = @{
        "7zip" = $false
        "winrar" = $false
        "tar" = $false
    }

    # Check for 7-Zip
    $7zipPaths = @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe",
        "${env:ProgramFiles}\7-Zip\7z.exe",
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
        "$env:ChocolateyInstall\tools\7z.exe"
    )
    
    foreach ($path in $7zipPaths) {
        if (Test-Path $path) {
            $tools["7zip"] = $path
            break
        }
    }

    # Check for WinRAR
    $winrarPaths = @(
        "C:\Program Files\WinRAR\Rar.exe",
        "C:\Program Files (x86)\WinRAR\Rar.exe", 
        "${env:ProgramFiles}\WinRAR\Rar.exe",
        "${env:ProgramFiles(x86)}\WinRAR\Rar.exe"
    )
    
    foreach ($path in $winrarPaths) {
        if (Test-Path $path) {
            $tools["winrar"] = $path
            break
        }
    }

    # Check for Microsoft's tar command
    if (Get-Command tar -ErrorAction SilentlyContinue) {
        $tools["tar"] = "tar"
    }

    return $tools
}

# Determine compression format based on file extension or user preference
function Get-CompressionFormat {
    param(
        [string]$Filename,
        [string]$PreferredFormat = $null
    )

    if ($PreferredFormat) {
        return $PreferredFormat.ToLower()
    }

    # Determine format from extension
    $extension = [System.IO.Path]::GetExtension($Filename).ToLower()
    switch ($extension) {
        ".zip" { return "zip" }
        ".tar.gz" { return "tar.gz" }
        ".gz" { return "gzip" }
        ".gzip" { return "gzip" }
        ".tar" { return "tar" }
        ".tgz" { return "tar.gz" }
        ".rar" { return "rar" }
        default { return "zip" } # Default to zip
    }
}

function Compress-Item {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        
        [Parameter()]
        [string]$Destination,
        
        [Parameter()]
        [ValidateSet("zip", "gzip", "tar.gz", "rar")]
        [string]$Format = "zip"
    )

    try {
        # Resolve full path for source
        $Source = Resolve-Path $Source -ErrorAction Stop | Select-Object -ExpandProperty Path

        # Determine if source is file or directory
        $isDirectory = (Get-Item $Source).PSIsContainer

        # Generate default destination if not provided
        if ([string]::IsNullOrEmpty($Destination)) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Source)
            $parentPath = Split-Path -Parent $Source
            
            switch ($Format) {
                "zip" { $Destination = Join-Path $parentPath "$baseName.zip" }
                "gzip" { $Destination = Join-Path $parentPath "$baseName.gz" }
                "tar.gz" { $Destination = Join-Path $parentPath "$baseName.tar.gz" }
                "rar" { $Destination = Join-Path $parentPath "$baseName.rar" }
            }
        }

        # Ensure destination has correct extension
        if (-not [System.IO.Path]::GetExtension($Destination)) {
            switch ($Format) {
                "zip" { $Destination += ".zip" }
                "gzip" { $Destination += ".gz" }
                "tar.gz" { $Destination += ".tar.gz" }
                "rar" { $Destination += ".rar" }
            }
        }

        # Get available tools
        $tools = Get-AvailableTools

        Log-Info "📦 Compressing '$Source' to '$Destination' (format: $Format)"

        switch ($Format) {
            "zip" {
                if ($tools["7zip"]) {
                    # Use 7-Zip
                    $result = Use-7Zip -Action "compress" -Source $Source -Destination $Destination -Format "zip"
                } else {
                    # Fall back to PowerShell's Compress-Archive
                    Microsoft.PowerShell.Archive\Compress-Archive -Path $Source -DestinationPath $Destination -Force
                    $result = Ok -Value "Compressed to $Destination using PowerShell"
                }
            }

            "gzip" {
                if ($isDirectory) {
                    return Err "GZIP format cannot compress directories directly. Use tar.gz for directories."
                }
                
                if ($tools["7zip"]) {
                    # Use 7-Zip
                    $result = Use-7Zip -Action "compress" -Source $Source -Destination $Destination -Format "gzip"
                } elseif ($tools["tar"]) {
                    # Use tar command
                    $result = Use-Tar -Action "compress" -Source $Source -Destination $Destination -Format "gzip"
                } else {
                    return Err "Neither 7-Zip nor tar command available for GZIP compression"
                }
            }

            "tar.gz" {
                if ($tools["7zip"]) {
                    # Use 7-Zip (create tar first, then gzip)
                    $tarFile = [System.IO.Path]::ChangeExtension($Destination, ".tar")
                    $result = Use-7Zip -Action "compress" -Source $Source -Destination $tarFile -Format "tar"
                    if ($result.ok) {
                        $result = Use-7Zip -Action "compress" -Source $tarFile -Destination $Destination -Format "gzip"
                        Remove-Item $tarFile -Force
                    }
                } elseif ($tools["tar"]) {
                    # Use tar command
                    $result = Use-Tar -Action "compress" -Source $Source -Destination $Destination -Format "tar.gz"
                } else {
                    return Err "Neither 7-Zip nor tar command available for TAR.GZ compression"
                }
            }

            "rar" {
                if ($tools["winrar"]) {
                    # Use WinRAR
                    $result = Use-WinRAR -Action "compress" -Source $Source -Destination $Destination
                } elseif ($tools["7zip"]) {
                    return Err "7-Zip cannot create RAR archives. Please install WinRAR."
                } else {
                    return Err "WinRAR is required to create RAR archives"
                }
            }
        }

        if ($result.ok) {
            $fileInfo = Get-Item $Destination
            $fileSize = [math]::Round($fileInfo.Length / 1MB, 2)
            Log-Info "✅ Compression completed. File size: $fileSize MB"
        } else {
            Log-Error "❌ Compression failed: $($result.error)"
        }

        return $result
    }
    catch {
        Log-Error "❌ Compression failed: $_"
        return Err "Compression failed: $_"
    }
}

function Expand-Item {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        
        [Parameter()]
        [string]$Destination
    )

    try {
        # Resolve full path for source
        $Source = Resolve-Path $Source -ErrorAction Stop | Select-Object -ExpandProperty Path

        # Determine format from extension
        $format = Get-CompressionFormat -Filename $Source

        # Generate default destination if not provided
        if ([string]::IsNullOrEmpty($Destination)) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Source)
            if ($format -eq "tar.gz" -and $baseName.EndsWith(".tar")) {
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($baseName)
            }
            $Destination = Join-Path (Split-Path -Parent $Source) $baseName
        }

        # Get available tools
        $tools = Get-AvailableTools

        Log-Info "📂 Extracting '$Source' to '$Destination' (format: $format)"

        switch ($format) {
            "zip" {
                if ($tools["7zip"]) {
                    # Use 7-Zip
                    $result = Use-7Zip -Action "extract" -Source $Source -Destination $Destination
                } else {
                    # Fall back to PowerShell's Expand-Archive
                    if (-not (Test-Path $Destination)) {
                        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
                    }
                    Microsoft.PowerShell.Archive\Expand-Archive -Path $Source -DestinationPath $Destination -Force
                    $result = Ok -Value "Extracted to $Destination using PowerShell"
                }
            }

            "gzip" {
                if ($tools["7zip"]) {
                    # Use 7-Zip
                    $result = Use-7Zip -Action "extract" -Source $Source -Destination $Destination
                } elseif ($tools["tar"]) {
                    # Use tar command
                    $result = Use-Tar -Action "extract" -Source $Source -Destination $Destination -Format "gzip"
                } else {
                    return Err "Neither 7-Zip nor tar command available for GZIP extraction"
                }
            }

            "tar.gz" {
                if ($tools["tazr"]) {
                    # Prefer tar command for tar.gz files
                    $result = Use-Tar -Action "extract" -Source $Source -Destination $Destination -Format "tar.gz"
                } elseif ($tools["7zip"]) {
                    # Use 7-Zip - need to do a two-step extraction
                    
                    # Create a temporary directory
                    $tempDirGuid = [System.Guid]::NewGuid().ToString()
                    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) $tempDirGuid
                    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                    
                    try {
                        # First step: Extract gz to a temporary location
                        $args = "e", $Source, "-o$tempDir", "-y"
                        $process = Start-Process -FilePath $tools["7zip"] -ArgumentList $args -Wait -NoNewWindow -PassThru
                        
                        if ($process.ExitCode -eq 0) {
                            # Find the extracted file (could be .tar or any other name)
                            $extractedFiles = Get-ChildItem -Path $tempDir -File
                            
                            if ($extractedFiles.Count -eq 1) {
                                # Second step: Extract the inner archive to destination
                                $result = Use-7Zip -Action "extract" -Source $extractedFiles[0].FullName -Destination $Destination
                            } else {
                                return Err "Unexpected number of files extracted: $($extractedFiles.Count)"
                            }
                        } else {
                            return Err "Failed to extract gzip wrapper"
                        }
                    }
                    finally {
                        # Clean up temporary directory
                        if (Test-Path $tempDir) {
                            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                        }
                    }
                } else {
                    return Err "Neither 7-Zip nor tar command available for TAR.GZ extraction"
                }
            }

            "rar" {
                if ($tools["winrar"]) {
                    # Use WinRAR
                    $result = Use-WinRAR -Action "extract" -Source $Source -Destination $Destination
                } elseif ($tools["7zip"]) {
                    # 7-Zip can extract RAR files
                    $result = Use-7Zip -Action "extract" -Source $Source -Destination $Destination
                } else {
                    return Err "Neither WinRAR nor 7-Zip available for RAR extraction"
                }
            }

            default {
                return Err "Unsupported archive format: $format"
            }
        }

        if ($result.ok) {
            Log-Info "✅ Extraction completed successfully"
        }

        return $result
    }
    catch {
        Log-Error "❌ Extraction failed: $_"
        return Err "Extraction failed: $_"
    }
}

# Helper function for 7-Zip operations
function Use-7Zip {
    param(
        [ValidateSet("compress", "extract")]
        [string]$Action,
        [string]$Source,
        [string]$Destination,
        [string]$Format = "zip"
    )

    $tools = Get-AvailableTools
    $7zipPath = $tools["7zip"]

    if (-not $7zipPath) {
        return Err "7-Zip not found"
    }

    try {
        switch ($Action) {
            "compress" {
                switch ($Format) {
                    "zip" { $args = "a", "-tzip", $Destination, $Source }
                    "gzip" { $args = "a", "-tgzip", $Destination, $Source }
                    "tar" { $args = "a", "-ttar", $Destination, $Source }
                    default { return Err "Unsupported format for 7-Zip: $Format" }
                }
            }
            "extract" {
                if ($Format -eq "tar") {
                    # Special handling for tar files - extract to specific directory
                    $args = "x", $Source, "-o$Destination", "-y"
                } else {
                    # Regular extraction
                    $args = "x", $Source, "-o$Destination", "-y"
                }
            }
        }

        $process = Start-Process -FilePath $7zipPath -ArgumentList $args -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            return Ok -Value "Operation completed successfully using 7-Zip"
        } else {
            return Err "7-Zip operation failed with exit code: $($process.ExitCode)"
        }
    }
    catch {
        return Err "7-Zip operation failed: $_"
    }
}

# Helper function for WinRAR operations
function Use-WinRAR {
    param(
        [ValidateSet("compress", "extract")]
        [string]$Action,
        [string]$Source,
        [string]$Destination
    )

    $tools = Get-AvailableTools
    $winrarPath = $tools["winrar"]

    if (-not $winrarPath) {
        return Err "WinRAR not found"
    }

    try {
        switch ($Action) {
            "compress" {
                $args = "a", "-r", $Destination, $Source
            }
            "extract" {
                # Create destination directory if it doesn't exist
                if (-not (Test-Path $Destination)) {
                    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
                }
                $args = "x", "-y", $Source, $Destination
            }
        }

        $process = Start-Process -FilePath $winrarPath -ArgumentList $args -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            return Ok -Value "Operation completed successfully using WinRAR"
        } else {
            return Err "WinRAR operation failed with exit code: $($process.ExitCode)"
        }
    }
    catch {
        return Err "WinRAR operation failed: $_"
    }
}

# Helper function for tar operations
function Use-Tar {
    param(
        [ValidateSet("compress", "extract")]
        [string]$Action,
        [string]$Source,
        [string]$Destination,
        [string]$Format = "tar.gz"
    )

    try {
        switch ($Action) {
            "compress" {
                switch ($Format) {
                    "gzip" {
                        # For single file gzip compression
                        $args = "-czf", $Destination, "-C", (Split-Path -Parent $Source), (Split-Path -Leaf $Source)
                    }
                    "tar.gz" {
                        # For tar.gz compression
                        $args = "-czf", $Destination, "-C", (Split-Path -Parent $Source), (Split-Path -Leaf $Source)
                    }
                    default {
                        return Err "Unsupported format for tar: $Format"
                    }
                }
            }
            "extract" {
                # Create destination directory if it doesn't exist
                if (-not (Test-Path $Destination)) {
                    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
                }
                
                switch ($Format) {
                    "gzip" {
                        # Extract gzip file
                        $args = "-xzf", $Source, "-C", $Destination
                    }
                    "tar.gz" {
                        # Extract tar.gz file
                        $args = "-xzf", $Source, "-C", $Destination
                    }
                    default {
                        $args = "-xf", $Source, "-C", $Destination
                    }
                }
            }
        }

        $process = Start-Process -FilePath "tar" -ArgumentList $args -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            return Ok -Value "Operation completed successfully using tar"
        } else {
            return Err "tar operation failed with exit code: $($process.ExitCode)"
        }
    }
    catch {
        return Err "tar operation failed: $_"
    }
}
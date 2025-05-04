# all/my/homies/download.ps1
# File download utility optimized for performance with BITS support
function download {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Position = 1)]
        [string]$OutFile = "",
        
        [Parameter(Position = 2)]
        [switch]$UseBits = $true,
        
        [Parameter(Position = 3)]
        [switch]$ShowProgress = $false,
        
        [Parameter(Position = 4)]
        [switch]$Resume = $false,
        
        [Parameter(Position = 5)]
        [int]$Timeout = 300,
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    try {
        # If output file not specified, derive from URL
        if ([string]::IsNullOrWhiteSpace($OutFile)) {
            $uri = [System.Uri]$Url
            $OutFile = [System.IO.Path]::GetFileName($uri.LocalPath)
            if ([string]::IsNullOrWhiteSpace($OutFile)) {
                $OutFile = "download_" + [guid]::NewGuid().ToString("N").Substring(0, 8)
            }
        }

        # Ensure output directory exists
        $outDir = Split-Path -Parent $OutFile
        if (-not [string]::IsNullOrWhiteSpace($outDir) -and -not (Test-Path $outDir)) {
            New-Item -ItemType Directory -Path $outDir -Force | Out-Null
        }

        Log-Info "Downloading from: $Url"
        Log-Info "Saving to: $OutFile"

        # Start timing
        Start-Clock

        $downloadSuccess = $false
        $downloadMethod = ""

        # Try BITS first if requested
        if ($UseBits) {
            $bitsAvailable = $false
            try {
                if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
                    $bitsAvailable = $true
                }
            }
            catch {
                $bitsAvailable = $false
            }

            if ($bitsAvailable) {
                try {
                    Log-Info "Using BITS transfer..."
                    
                    # Use synchronous BITS transfer to avoid the progress issue
                    Start-BitsTransfer -Source $Url -Destination $OutFile -DisplayName "AMH2W Download" -Description "Downloading $OutFile"
                    
                    $downloadMethod = "BITS"
                    $downloadSuccess = $true
                    Log-Success "Download completed via BITS"
                }
                catch {
                    # Check if it's the specific Int64 error
                    if ($_.Exception.Message -like "*Cannot convert value*Int64*") {
                        Log-Warning "BITS failed due to file size issue, falling back to WebClient..."
                    }
                    else {
                        Log-Warning "BITS transfer failed: $_"
                    }
                    Log-Info "Falling back to WebClient..."
                }
            }
            else {
                Log-Warning "BITS not available, using WebClient..."
            }
        }

        # Fallback to WebClient
        if (-not $downloadSuccess) {
            try {
                Log-Info "Using WebClient..."
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($Url, $OutFile)
                
                if (Test-Path $OutFile -and (Get-Item $OutFile).Length -gt 0) {
                    $downloadMethod = "WebClient"
                    $downloadSuccess = $true
                    Log-Success "Download completed via WebClient"
                }
                else {
                    throw "Downloaded file is empty or does not exist"
                }
            }
            catch {
                Log-Error "Download failed: $_"
                return Err "Download failed: $_"
            }
            finally {
                if ($webClient) {
                    $webClient.Dispose()
                }
            }
        }

        # Final verification
        if (-not $downloadSuccess -or -not (Test-Path $OutFile)) {
            Log-Error "Download failed"
            return Err "Download failed"
        }

        # Get file info
        $fileInfo = Get-Item $OutFile
        $fileSize = $fileInfo.Length
        $fileSizeFormatted = Format-ByteSize -Bytes $fileSize

        # Calculate stats
        $clockResult = Stop-Clock
        $totalSeconds = [double]$clockResult.Value.TotalSeconds
        $downloadSpeedBps = $fileSize / $totalSeconds
        $downloadSpeedFormatted = Format-ByteSize -Bytes $downloadSpeedBps

        Log-Success "Downloaded $fileSizeFormatted in $($clockResult.Value.ElapsedTime) ($downloadSpeedFormatted/s) using $downloadMethod"

        return Ok -Value @{
            File = $OutFile
            FileSize = $fileSize
            FileSizeFormatted = $fileSizeFormatted
            Duration = $clockResult.Value.ElapsedTime
            DownloadSpeed = $downloadSpeedBps
            DownloadSpeedFormatted = "$downloadSpeedFormatted/s"
            Method = $downloadMethod
            Clock = $clockResult.Value
        } -Message "File downloaded successfully to $OutFile"
    }
    catch {
        Log-Error "Download failed: $_"
        return Err "Download failed: $_"
    }
}

# Helper function to format byte sizes
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

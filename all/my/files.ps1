# files.ps1
# Opens File Explorer at the specified location

function files {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location)
    )
    
    # Expand relative paths and environment variables
    $Path = [System.Environment]::ExpandEnvironmentVariables($Path)
    
    # If path doesn't start with a drive letter or UNC path, assume it's relative
    if (-not ($Path -match "^[A-Z]:\\" -or $Path -match "^\\\\")) {
        $Path = Join-Path -Path (Get-Location).Path -ChildPath $Path
    }
    
    Write-Host "Opening File Explorer: " -NoNewline -ForegroundColor Cyan
    Write-Host $Path -ForegroundColor Green
    
    # Verify path exists
    if (-not (Test-Path -Path $Path)) {
        Write-Host "Warning: Path doesn't exist: $Path" -ForegroundColor Yellow
        
        # Check if parent directory exists
        $parentPath = Split-Path -Parent $Path
        if (-not [string]::IsNullOrEmpty($parentPath) -and (Test-Path -Path $parentPath)) {
            Write-Host "Opening parent directory instead: $parentPath" -ForegroundColor Yellow
            $Path = $parentPath
        }
        else {
            Write-Host "Error: Cannot open File Explorer - path doesn't exist" -ForegroundColor Red
            return $false
        }
    }
    
    # Start File Explorer with the path
    try {
        Start-Process -FilePath "explorer.exe" -ArgumentList $Path
        Write-Host "✅ File Explorer opened successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error: Failed to open File Explorer: $_" -ForegroundColor Red
        return $false
    }
}

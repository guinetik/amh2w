param(
    [Parameter(Position = 0)]
    [string]$Path,
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

function files() {
    $Context = New-PipelineContext

    # If no path specified, use current directory
    if ([string]::IsNullOrEmpty($Path)) {
        $Path = (Get-Location).Path
        Log info "Opening File Explorer on current directory: $Path" $Context
    }
    else {
        # Expand relative paths and environment variables
        $Path = [System.Environment]::ExpandEnvironmentVariables($Path)
    
        # If path doesn't start with a drive letter or UNC path, assume it's relative
        if (-not ($Path -match "^[A-Z]:\\" -or $Path -match "^\\\\")) {
            $Path = Join-Path -Path (Get-Location).Path -ChildPath $Path
        }
    
        Log info "Opening File Explorer on: $Path" $Context
    }

    $result = Invoke-Pipeline -Steps @(
        {
            # Verify path exists
            if (-not (Test-Path -Path $Path)) {
                Log warn "Path doesn't exist: $Path" $Context
            
                # Check if parent directory exists
                $parentPath = Split-Path -Parent $Path
                if (-not [string]::IsNullOrEmpty($parentPath) -and (Test-Path -Path $parentPath)) {
                    Log info "Opening parent directory instead: $parentPath" $Context
                    $script:Path = $parentPath
                    return Ok "Using parent directory instead"
                }
                else {
                    return Err "Cannot open File Explorer - path doesn't exist: $Path"
                }
            }
            return Ok "Path verified"
        },
        {
            # Start File Explorer with the path
            try {
                Start-Process -FilePath "explorer.exe" -ArgumentList $Path
                return Ok "File Explorer opened on: $Path"
            }
            catch {
                return Err "Failed to open File Explorer: $_"
            }
        }
    ) -Context $Context

    if ($result) {
        Write-Host "✅ File Explorer opened on: $Path" -ForegroundColor Green
    }

    # Return result for pipeline
    return Ok "File Explorer opened on: $Path"
}

if ($Path) {
    files
}

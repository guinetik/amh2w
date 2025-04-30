# Script path resolution cache
$script:scriptPathCache = @{}

function Resolve-ScriptPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptName
    )

    # Check cache first
    if ($script:scriptPathCache.ContainsKey($ScriptName)) {
        return $script:scriptPathCache[$ScriptName]
    }

    # Get all possible base paths from environment
    $basePaths = @()
    
    # Add workspace root if available
    if ($env:WORKSPACE_ROOT) {
        $basePaths += $env:WORKSPACE_ROOT
    }
    
    # Add current script's directory and its parent
    $basePaths += $PSScriptRoot
    $basePaths += (Split-Path -Parent $PSScriptRoot)

    # Add core directory if it exists
    $corePath = Join-Path (Split-Path -Parent $PSScriptRoot) "core"
    if (Test-Path $corePath) {
        $basePaths += $corePath
    }

    # Remove duplicates and ensure paths exist
    $basePaths = $basePaths | Select-Object -Unique | Where-Object { Test-Path $_ }

    # Search for the script in all base paths
    foreach ($path in $basePaths) {
        $scriptPath = Join-Path $path $ScriptName
        if (Test-Path $scriptPath) {
            # Cache the result
            $script:scriptPathCache[$ScriptName] = $scriptPath
            return $scriptPath
        }
    }

    # If we get here, the script wasn't found
    return $null
}

function Import-Script {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptName
    )

    Write-Host "Importing script: $ScriptName"

    $scriptPath = Resolve-ScriptPath -ScriptName $ScriptName
    
    if (-not $scriptPath) {
        Write-Error "Script not found: $ScriptName"
        return $false
    }

    Write-Host "Importing script: $scriptPath"

    try {
        . $scriptPath
        return $true
    }
    catch {
        Write-Error "Failed to import script $ScriptName : $($_.Exception.Message)"
        return $false
    }
}
# core/command.ps1
# Core command handling

function Get-AvailableCommands {
    param(
        [string]$BasePath
    )
    
    $result = @{
        Namespaces = @()
        Commands = @()
    }
    
    # Get subdirectories (namespaces)
    $dirs = Get-ChildItem -Path $BasePath -Directory | Select-Object -ExpandProperty Name
    if ($dirs) {
        $result.Namespaces = $dirs
    }
    
    # Get script files (commands)
    $files = Get-ChildItem -Path $BasePath -Filter "*.ps1" | 
             Where-Object { $_.BaseName -ne (Split-Path $BasePath -Leaf) } |
             Select-Object -ExpandProperty BaseName
    
    if ($files) {
        $result.Commands = $files
    }
    
    return $result
}

function Show-CommandHelp {
    param(
        [string]$CommandPath,
        [string]$CommandChain = ""
    )
    
    $available = Get-AvailableCommands -BasePath $CommandPath
    
    Write-Host "AMH2W Command Chain: $CommandChain" -ForegroundColor Cyan
    Write-Host ""
    
    if ($available.Namespaces.Count -gt 0) {
        Write-Host "Available Namespaces:" -ForegroundColor Yellow
        foreach ($ns in $available.Namespaces) {
            Write-Host "  $ns" -ForegroundColor Green
        }
        Write-Host ""
    }
    
    if ($available.Commands.Count -gt 0) {
        Write-Host "Available Commands:" -ForegroundColor Yellow
        foreach ($cmd in $available.Commands) {
            Write-Host "  $cmd" -ForegroundColor White
        }
        Write-Host ""
    }
    
    if ($available.Namespaces.Count -eq 0 -and $available.Commands.Count -eq 0) {
        Write-Host "No commands available in this namespace." -ForegroundColor Red
    }
    
    Write-Host "Example: $CommandChain [command]" -ForegroundColor Gray
}

function Invoke-CommandChain {
    param(
        [string]$CommandChain,
        [string[]]$Arguments
    )
    
    # Split command chain
    $parts = $CommandChain -split ' '
    
    # Get the module root
    $currentPath = $PSScriptRoot
    $moduleRoot = Split-Path -Parent $currentPath
    $currentPath = Join-Path $moduleRoot "all"
    
    # Navigate through the chain
    $chain = ""
    foreach ($part in $parts) {
        $chain = if ($chain) { "$chain $part" } else { $part }
        
        # Check if this part exists as a directory
        $nextPath = Join-Path $currentPath $part
        if (Test-Path $nextPath -PathType Container) {
            $currentPath = $nextPath
            
            # Load the corresponding script for this namespace
            $scriptPath = Join-Path $currentPath "$part.ps1"
            if (Test-Path $scriptPath) {
                # Already loaded in module initialization
            }
        }
        else {
            # Check if it's a script
            $scriptPath = Join-Path $currentPath "$part.ps1"
            if (Test-Path $scriptPath) {
                # Call the function with the provided arguments
                $commandFunction = Get-Command $part -ErrorAction SilentlyContinue
                if ($commandFunction) {
                    return & $commandFunction @Arguments
                }
                else {
                    return Err "Command function '$part' not found, but script exists."
                }
            }
            else {
                # Command not found, show help
                Show-CommandHelp -CommandPath $currentPath -CommandChain $chain
                return Err "Command or namespace '$part' not found."
            }
        }
    }
    
    # If we reach here, we just navigated to a namespace, show help
    Show-CommandHelp -CommandPath $currentPath -CommandChain $chain
    return Ok $null
}

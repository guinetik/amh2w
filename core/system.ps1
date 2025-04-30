# system.ps1
# Core system functions for handling elevation and other system-level operations

function Test-IsAdmin {
    <#
    .SYNOPSIS
    Checks if the current PowerShell session is running with administrator privileges.
    
    .DESCRIPTION
    Returns $true if the current session is running as Administrator, $false otherwise.
    
    .EXAMPLE
    if (Test-IsAdmin) {
        Write-Host "Running as admin"
    }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Elevate {
    <#
    .SYNOPSIS
    Elevates the current command to run with administrator privileges.
    
    .DESCRIPTION
    Restarts the specified command in a new PowerShell window with elevated privileges.
    
    .PARAMETER Command
    The command to execute with elevation.
    
    .PARAMETER Prompt
    If set to $true, prompts the user before elevating.
    
    .PARAMETER Description
    Description of why elevation is required, shown in the prompt.
    
    .PARAMETER KeepOpen
    If set to $true, keeps the elevated PowerShell window open after command execution.
    
    .EXAMPLE
    Invoke-Elevate -Command "all my homies install choco" -Prompt $true -Description "Installing Chocolatey requires administrator privileges" -KeepOpen $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [Parameter()]
        [bool]$Prompt = $false,
        
        [Parameter()]
        [string]$Description = "This operation requires administrator privileges",
        
        [Parameter()]
        [bool]$KeepOpen = $false
    )
    
    # If already admin, do nothing
    if (Test-IsAdmin) {
        Write-Verbose "Already running as administrator"
        return
    }
    
    # Prompt for confirmation if requested
    if ($Prompt) {
        $title = "Elevation Required"
        $message = "$Description`n`nDo you want to continue?"
        
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Continues with elevated privileges."
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Cancels the operation."
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        
        $result = $host.UI.PromptForChoice($title, $message, $options, 0)
        
        if ($result -ne 0) {
            Write-Host "Operation cancelled by user."
            return
        }
    }
    
    # Prepare the command
    $cmdScript = $Command
    
    # Add a pause at the end if KeepOpen is true
    if ($KeepOpen) {
        $cmdScript = "$Command; Write-Host '`nPress any key to continue...' -ForegroundColor Cyan; `$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')"
    }
    
    # Start a new elevated PowerShell process
    $arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmdScript`""
    
    try {
        Start-Process PowerShell -Verb RunAs -ArgumentList $arguments -Wait
        Write-Verbose "Command executed with elevation"
    }
    catch {
        Write-Error "Failed to elevate command: $_"
    }
}

# Add aliases for easier use
Set-Alias -Name isAdmin -Value Test-IsAdmin
Set-Alias -Name elevate -Value Invoke-Elevate

# Export the functions
Export-ModuleMember -Function Test-IsAdmin, Invoke-Elevate -Alias isAdmin, elevate

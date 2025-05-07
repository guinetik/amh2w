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
        [bool]$KeepOpen = $true
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
    
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell Core (6.x+)
        $psExecutable = "pwsh"
    } else {
        # Windows PowerShell 5.x
        $psExecutable = "powershell"
    }
    
    # Start a new elevated PowerShell process using the same version
    $arguments = "-ExecutionPolicy Bypass -Command `"$cmdScript`""
    
    try {
        Start-Process $psExecutable -Verb RunAs -ArgumentList $arguments -Wait
        Write-Verbose "Command executed with elevation using $psExecutable"
    }
    catch {
        Write-Error "Failed to elevate command: $_"
    }
}

function Invoke-VerboseCommand {
    param (
        [string]$Command
    )

    # Detect current PowerShell version
    $currentProcess = Get-Process -Id $PID
    $psExecutable = $currentProcess.Path
    
    # If we couldn't get the path from the process, fall back to detecting version
    if (-not $psExecutable) {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            # PowerShell Core (6.x+)
            $psExecutable = "pwsh.exe"
        } else {
            # Windows PowerShell 5.x
            $psExecutable = "powershell.exe"
        }
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $psExecutable
    $psi.Arguments = "-NoProfile -Command $Command"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.Start() | Out-Null

    while (-not $proc.HasExited) {
        $out = $proc.StandardOutput.ReadLine()
        if ($out) { Write-Host $out -ForegroundColor DarkGray}
    }

    while (-not $proc.StandardError.EndOfStream) {
        $err = $proc.StandardError.ReadLine()
        if ($err) { Log-Error $err }
    }

    $proc.WaitForExit()
    return $proc.ExitCode
}

function Invoke-Powershell {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Arguments = @()
    )
    $Arguments += "-Command $Command"
    $executable = if ($PSVersionTable.PSVersion.Major -ge 5) { "pwsh.exe" } else { "powershell.exe" }
    Log-Info "Executing $Command with $executable"
    Start-Process $executable -ArgumentList $Arguments
}

function registry {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

function Set-RegistryValues {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [hashtable]$PropertyValues,

        [switch]$EnsurePath
    )

    if ($EnsurePath.IsPresent) {
        registry $Path
    }

    foreach ($name in $PropertyValues.Keys) {
        $item = $PropertyValues[$name]
        if ($item -is [hashtable] -and $item.ContainsKey('Value')) {
            if ($item.ContainsKey('Type')) {
                Set-ItemProperty -Path $Path -Name $name -Value $item.Value -Type $item.Type -ErrorAction Stop
            } else {
                 Set-ItemProperty -Path $Path -Name $name -Value $item.Value -ErrorAction Stop
            }
        } else {
            Set-ItemProperty -Path $Path -Name $name -Value $item -ErrorAction Stop
        }
    }
}
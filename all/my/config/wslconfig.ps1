<#
.SYNOPSIS
    Unified WSL management utility for common WSL tasks (location, install, backup, resize, export, import, list, enable).
.DESCRIPTION
    Provides a single entry point for managing WSL distros, including installation, backup, resizing, export/import, listing, and enabling WSL features. Wraps helper functions for each action.
.PARAMETER Action
    The action to perform. One of: location, install, backup, resize, export, import, list, enable.
.PARAMETER Distro
    The name of the WSL distro to operate on (default: Ubuntu). For import, this is the new distro name.
.PARAMETER Arguments
    Additional arguments for the action (e.g., backup path, size, etc.).
.EXAMPLE
    wslconfig -Action install -Distro Ubuntu
    # Installs the Ubuntu WSL distro.
.EXAMPLE
    wslconfig -Action backup -Distro Ubuntu -Arguments 'C:\backups\ubuntu-backup.tar'
    # Backs up Ubuntu to the specified path.
.OUTPUTS
    Returns Ok/Err objects or writes output to the host.
#>
function wslconfig {
    [CmdletBinding(DefaultParameterSetName='Named', SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet('location', 'install', 'backup', 'resize', 'export', 'import', 'list', 'enable')]
        [string]$Action,

        [Parameter(Mandatory=$false, Position=1)]
        [string]$Distro = "Ubuntu",

        # Capture all remaining arguments positionally
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    # Base parameters for most actions
    $params = @{ Distro = $Distro }

    switch ($Action) {
        "location" {
            # No extra args expected
            Get-VhdxPath @params
        }
        "install" {
            # No extra args expected
             if ($PSCmdlet.ShouldProcess($Distro, "Install")) {
                 Install-WslDistro @params
             }
        }
        "backup" {
            # Expects: <BackupPath>
            if ($Arguments.Count -ge 1) { $params['BackupPath'] = $Arguments[0] }
             if ($PSCmdlet.ShouldProcess("$Distro to $($params.BackupPath)", "Backup")) {
                 Backup-WslDistro @params
             }
        }
        "resize" {
             # Expects: <Size>
            if ($Arguments.Count -ge 1) { $params['Size'] = $Arguments[0] }
             if ($PSCmdlet.ShouldProcess("$Distro to $($params.Size)", "Resize")) {
                 Resize-WslDisk @params
             }
        }
        "export" {
            # Expects: <ExportPath>
            if ($Arguments.Count -ge 1) { $params['ExportPath'] = $Arguments[0] }
             if ($PSCmdlet.ShouldProcess("$Distro to $($params.ExportPath)", "Export")) {
                 Export-WslDistro @params
             }
        }
        "import" {
            # Expects: <InstallPath> <ImportFile>
            # For import, $Distro is the NewDistroName
            $params = @{ DistroName = $Distro }
            if ($Arguments.Count -ge 1) { $params['InstallPath'] = $Arguments[0] }
            if ($Arguments.Count -ge 2) { $params['TarPath'] = $Arguments[1] }
             if ($PSCmdlet.ShouldProcess("$($params.TarPath) to $Distro at $($params.InstallPath)", "Import")) {
                 Import-WslDistro @params
             }
        }
        "list" {
            # No extra args expected
            Show-WslDistros
        }
        "enable" {
            # No extra args expected
            Enable-Wsl
        }
    }
}

<#
.SYNOPSIS
    Lists all installed and available WSL distros and status.
.DESCRIPTION
    Shows verbose and online WSL distros, and current WSL status using wsl.exe.
.EXAMPLE
    Show-WslDistros
    # Lists all WSL distros and status.
.OUTPUTS
    Ok/Err object, writes to host.
#>
function Show-WslDistros {
    try {
        Write-Host "🔍 Listing WSL distros..." -ForegroundColor Cyan
        wsl.exe --list --verbose
        Write-Host "Online distros:" -ForegroundColor Cyan
        wsl.exe --list --online
        Write-Host "Status:" -ForegroundColor Cyan
        wsl.exe --status
        return Ok "WSL distros listed." 
    } catch {
        Write-Host "⚠️ Error: $($Error[0]) in script line $($_.InvocationInfo.ScriptLineNumber)."
        return Err "Failed to list WSL distros."
    }
}

<#
.SYNOPSIS
    Gets the VHDX (virtual disk) path for a given WSL distro.
.DESCRIPTION
    Looks up the registry for the specified distro and returns the path to its ext4.vhdx file.
.PARAMETER Distro
    The name of the WSL distro.
.EXAMPLE
    Get-VhdxPath -Distro Ubuntu
    # Returns the VHDX path for Ubuntu.
.OUTPUTS
    Ok/Err object with the VHDX path or error message.
#>
function Get-VhdxPath {
    param([string]$Distro)

    $key = Get-ChildItem -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss |
        Where-Object { $_.GetValue("DistributionName") -eq $Distro }

    if ($key) {
        $path = Join-Path $key.GetValue("BasePath") "ext4.vhdx"
        return Ok $path
    } else {
        Write-Host "❌ Distribution '$Distro' not found" -ForegroundColor Red
        return Err "Distribution '$Distro' not found"
    }
}

<#
.SYNOPSIS
    Installs a WSL distro (default Ubuntu if none specified).
.DESCRIPTION
    Installs the specified WSL distro using a custom install command.
.PARAMETER Distro
    The name of the WSL distro to install.
.EXAMPLE
    Install-WslDistro -Distro Ubuntu
    # Installs Ubuntu.
.OUTPUTS
    Ok/Err object or writes to host.
#>
function Install-WslDistro {
    <#
    .SYNOPSIS
    Installs a WSL distro (default Ubuntu if none specified).
    .EXAMPLE
    Install-WslDistro "Ubuntu"  # Installs Ubuntu
    Install-WslDistro "Debian"  # Installs Debian
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Distro
    )
    if ($PSCmdlet.ShouldProcess($Distro, "Install WSL Distro")) {
        Write-Host "🚀 Installing $Distro ..." -ForegroundColor Cyan
        try {
            return all my homies install distro "$Distro"
        } catch {
            Write-Host "❌ Failed to install $Distro`: $_" -ForegroundColor Red
            return Err "Failed to install $Distro`: $_"
        }
    }
}

<#
.SYNOPSIS
    Backs up a WSL distro to a .tar file.
.DESCRIPTION
    Exports the specified WSL distro to a tar archive for backup purposes.
.PARAMETER Distro
    The name of the WSL distro to back up.
.PARAMETER BackupPath
    The file path to save the backup tar file.
.EXAMPLE
    Backup-WslDistro -Distro Ubuntu -BackupPath 'C:\backups\ubuntu-backup.tar'
    # Backs up Ubuntu to the specified path.
.OUTPUTS
    Ok/Err object or writes to host.
#>
function Backup-WslDistro {
    <#
    .SYNOPSIS
    Backs up a WSL distro to a .tar file.
    .EXAMPLE
    Backup-WslDistro -Distro "Ubuntu" -BackupPath "C:\backups\ubuntu-backup.tar"
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Distro,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$BackupPath
    )
    if ($PSCmdlet.ShouldProcess("$Distro to $BackupPath", "Export WSL Distro")) {
        Write-Host "💾 Backing up $Distro to $BackupPath ..." -ForegroundColor Cyan
        try {
            wsl --export $Distro $BackupPath
            return Ok $BackupPath "✅ Backup saved."
        } catch {
            Write-Host "❌ Failed to export $Distro to $BackupPath`: $_" -ForegroundColor Red
            return Err "Failed to export $Distro to $BackupPath`: $_"
        }
    }
}

<#
.SYNOPSIS
    Resizes a WSL 2 distro's virtual disk (ext4.vhdx).
.DESCRIPTION
    Changes the size of the specified WSL distro's virtual disk. Supports size suffixes B/M/MB/G/GB/T/TB.
.PARAMETER Distro
    The name of the WSL distro to resize.
.PARAMETER Size
    The new size for the virtual disk (e.g., 50GB).
.EXAMPLE
    Resize-WslDisk -Distro Ubuntu -Size 50GB
    # Resizes Ubuntu's disk to 50GB.
.OUTPUTS
    Ok/Err object or writes to host.
#>
function Resize-WslDisk {
    <#
    .SYNOPSIS
    Resizes a WSL 2 distro's virtual disk (ext4.vhdx). Supports size suffixes B/M/MB/G/GB/T/TB.
    .EXAMPLE
    Resize-WslDisk -Distro "Ubuntu" -Size "50GB"  # Resizes to 50GB
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Distro,

        [Parameter(Mandatory=$true, Position=1)]
        [ValidatePattern('^\d+(B|M|MB|G|GB|T|TB)$')] # Validate size format
        [string]$Size
    )
    if ($PSCmdlet.ShouldProcess("$Distro to $Size", "Resize WSL Disk")) {
        Write-Host "📏 Resizing $Distro to $Size ..." -ForegroundColor Cyan
        try {
             wsl --manage $Distro --resize $Size
             return Ok $Size "✅ Resized $Distro to $Size"
        } catch {
            Write-Host "❌ Failed to resize $Distro to $Size`: $_" -ForegroundColor Red
            return Err "Failed to resize $Distro to $Size`: $_"
        }
    }
}

<#
.SYNOPSIS
    Exports a WSL distro to a .tar file (same as Backup-WslDistro).
.DESCRIPTION
    Exports the specified WSL distro to a tar archive for migration or backup.
.PARAMETER Distro
    The name of the WSL distro to export.
.PARAMETER ExportPath
    The file path to save the exported tar file.
.EXAMPLE
    Export-WslDistro -Distro Ubuntu -ExportPath 'C:\backups\ubuntu-export.tar'
    # Exports Ubuntu to the specified path.
.OUTPUTS
    Ok/Err object or writes to host.
#>
function Export-WslDistro {
    <#
    .SYNOPSIS
    Exports a WSL distro to a .tar file (same as Backup-WslDistro).
    .EXAMPLE
    Export-WslDistro -Distro "Ubuntu" -ExportPath "C:\backups\ubuntu-export.tar"
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Distro,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$ExportPath
    )
    # Use Backup-WslDistro directly, respecting ShouldProcess and containing its own logging/emojis
    Backup-WslDistro -Distro $Distro -BackupPath $ExportPath
}

<#
.SYNOPSIS
    Imports a WSL distro from a .tar file to a custom location.
.DESCRIPTION
    Imports a WSL distro from a tar archive to a specified install path, creating a new distro name.
.PARAMETER DistroName
    The name for the new WSL distro.
.PARAMETER InstallPath
    The directory to install the new WSL distro.
.PARAMETER ImportFile
    The path to the tar file to import.
.EXAMPLE
    Import-WslDistro -DistroName Ubuntu-Custom -InstallPath 'C:\wsl\custom-ubuntu' -ImportFile 'C:\backups\ubuntu-backup.tar'
    # Imports a new Ubuntu-Custom distro from the backup.
.OUTPUTS
    Ok/Err object or writes to host.
#>
function Import-WslDistro {
    <#
    .SYNOPSIS
    Imports a WSL distro from a .tar file to a custom location.
    .EXAMPLE
    Import-WslDistro -DistroName "Ubuntu-Custom" -InstallPath "C:\wsl\custom-ubuntu" -TarPath "C:\backups\ubuntu-backup.tar"
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$DistroName,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$InstallPath,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$ImportFile # Renamed from TarPath to match user edits
    )
    if ($PSCmdlet.ShouldProcess("$ImportFile to $DistroName at $InstallPath", "Import WSL Distro")) {
        Write-Host "📥 Importing $DistroName to $InstallPath ..." -ForegroundColor Cyan
        try {
            wsl --import $DistroName $InstallPath $ImportFile
            # Assuming Ok/Err functions exist globally or are defined elsewhere
            return Ok $InstallPath "✅ Imported $DistroName to $InstallPath"
        } catch {
            Write-Host "❌ Failed to import $DistroName from $ImportFile to $InstallPath`: $_" -ForegroundColor Red
            return Err "Failed to import $DistroName from $ImportFile to $InstallPath`: $_"
        }
    }
}

<#
.SYNOPSIS
    Enables WSL and VirtualMachinePlatform features on Windows.
.DESCRIPTION
    Ensures the required Windows features for WSL are enabled, elevating if necessary.
.EXAMPLE
    Enable-Wsl
    # Enables WSL and VirtualMachinePlatform features.
.OUTPUTS
    Ok/Err object or writes to host.
#>
function Enable-Wsl {
    [CmdletBinding()]
    param()

    # Elevate if needed
    if (-not (Test-IsAdmin)) {
        Invoke-Elevate -Command "all my homies config wsconfig enable" -Description "Enable WSL" -Prompt $true
        return
    }

    Log-Info "Enabling WSL and VirtualMachinePlatform..."

    try {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -ErrorAction Stop | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction Stop | Out-Null

        Log-Info "WSL and VirtualMachinePlatform features enabled successfully."
        Write-Host "✅ WSL enabled successfully." -ForegroundColor Green
        return Ok "WSL enabled successfully."
    }
    catch {
        Write-Host "❌ WSL enable failed: $_" -ForegroundColor Red
        return Err "WSL enable failed: $_"
    }
}

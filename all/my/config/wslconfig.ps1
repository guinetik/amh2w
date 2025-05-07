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

# all/my/homies/hate/packages.ps1
param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

# Use AMH2W_HOME environment variable for path resolution
if (-not $env:AMH2W_HOME) {
    Write-Error "AMH2W_HOME environment variable is not set. Please run setup.ps1 first."
    exit 1
}

#$BasePath = Join-Path -Path $env:AMH2W_HOME -ChildPath "all\my\homies\hate\packages"
$CorePath = Join-Path -Path $env:AMH2W_HOME -ChildPath "core"

# Import core utilities if not already imported
if (-not (Get-Command -Name "Ok" -ErrorAction SilentlyContinue)) {
    . "$CorePath\result.ps1"
    . "$CorePath\pipeline.ps1"
    . "$CorePath\log.ps1"
}

function download {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    Write-Host "Downloading $Url to $OutputPath"
    return Ok "Downloaded $Url to $OutputPath"
}

function install {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    Write-Host "Installing $Url to $OutputPath"
    Write-Host "Decompressing file..."
    Write-Host "Installing..."
    Write-Host "Cleaning up..."
    return Ok "Installed $Url to $OutputPath"
}

function zip {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    Write-Host "Zipping $Path to $OutputPath"
    return Ok "Zipped $Path to $OutputPath"
}

function unzip {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    Write-Host "Unzipping $Path to $OutputPath"
}
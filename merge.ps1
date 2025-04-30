param(
    [Parameter(Mandatory=$true)]
    [string]$Directory,
    [string]$OutputFile = "lib.ps1"
)

# Resolve and validate directory path
if (-Not (Test-Path -Path $Directory -PathType Container)) {
    Write-Error "The directory '$Directory' does not exist."
    exit 1
}

$FullDirectory = (Resolve-Path $Directory).Path
$FullOutputPath = Join-Path -Path (Get-Location) -ChildPath $OutputFile

# Clear or create output file
"" | Out-File -FilePath $FullOutputPath

# Generate tree structure and append to output file
"<# Directory Tree Structure #>`n" | Out-File -FilePath $FullOutputPath -Append
tree /f $FullDirectory | Out-File -FilePath $FullOutputPath -Append

# Append all file contents respecting original encodings
Get-ChildItem -Path $FullDirectory -File -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring($FullDirectory.Length + 1)
    
    # Add file header
    "`n`n<# File: $relativePath #>`n" | Out-File -FilePath $FullOutputPath -Append
    
    # Write content preserving original file encoding
    try {
        $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
        [System.IO.File]::WriteAllBytes($FullOutputPath, $bytes + [System.Text.Encoding]::$Encoding.GetBytes("`n"))
    }
    catch {
        Write-Error "Failed processing file: $relativePath. $_"
        exit 1
    }
}

Write-Host "Merged all files into $OutputFile successfully." -ForegroundColor Green

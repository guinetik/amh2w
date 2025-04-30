<#
.SYNOPSIS
    Merges all file contents from a directory into a single output file with a directory tree at the top.

.DESCRIPTION
    This script traverses a specified directory and combines all file contents into a single output file.
    It adds a directory tree structure at the beginning of the output file using the 'tree' command.

.PARAMETER InputDirectory
    The directory to traverse for files. Defaults to the current directory.

.PARAMETER OutputFile
    The file where all contents will be merged. Defaults to 'output.txt'.

.PARAMETER Recurse
    If specified, the script will recursively traverse subdirectories.

.PARAMETER ExcludeExtensions
    Array of file extensions to exclude from the merge (e.g., '.exe', '.dll').
    
.PARAMETER ExcludeFiles
    Array of filenames to exclude from the merge. LICENSE is excluded by default.

.EXAMPLE
    .\Merge-Files.ps1 -InputDirectory C:\Projects -OutputFile merged.txt

.EXAMPLE
    .\Merge-Files.ps1 -InputDirectory . -OutputFile code_archive.txt -Recurse -ExcludeExtensions @('.exe', '.dll', '.bin') -ExcludeFiles @('LICENSE', 'NOTICE')
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$InputDirectory = ".",

    [Parameter(Position = 1)]
    [string]$OutputFile = "output.txt",

    [Parameter()]
    [switch]$Recurse,

    [Parameter()]
    [string[]]$ExcludeExtensions = @(),
    
    [Parameter()]
    [string[]]$ExcludeFiles = @("LICENSE")
)

function Write-Tree {
    param (
        [string]$Path,
        [string]$OutputFile
    )

    $treeOutput = & tree.com /A /F $Path
    Set-Content -Path $OutputFile -Value $treeOutput -Encoding UTF8
    Add-Content -Path $OutputFile -Value "`n`n" -Encoding UTF8
    Add-Content -Path $OutputFile -Value ($("=") * 80) -Encoding UTF8
    Add-Content -Path $OutputFile -Value "`n`n" -Encoding UTF8
}

function Merge-Files {
    param (
        [string]$Directory,
        [string]$OutputFile,
        [bool]$Recursive = $false,
        [string[]]$ExcludeExts = @(),
        [string[]]$ExcludeFilesList = @()
    )

    # Resolve full paths
    $Directory = Resolve-Path $Directory
    $OutputFile = Join-Path (Get-Location) $OutputFile

    # Check if input directory exists
    if (-not (Test-Path -Path $Directory -PathType Container)) {
        Write-Error "Directory '$Directory' does not exist."
        return
    }

    # Create directory tree at the top
    Write-Host "Generating directory tree structure..." -ForegroundColor Cyan
    Write-Tree -Path $Directory -OutputFile $OutputFile

    # Get files to process
    $searchOption = if ($Recursive) { "AllDirectories" } else { "TopDirectoryOnly" }
    $files = Get-ChildItem -Path $Directory -File -Recurse:$Recursive
    
    # Filter out excluded extensions and files
    $files = $files | Where-Object { 
        $extension = [System.IO.Path]::GetExtension($_.Name)
        $fileName = $_.Name
        -not (($ExcludeExts -contains $extension) -or ($ExcludeFilesList -contains $fileName))
    }

    $fileCount = $files.Count
    Write-Host "Found $fileCount files to process..." -ForegroundColor Green

    # Check for README.md and process it first if found
    $readmeFile = $files | Where-Object { $_.Name -eq "README.md" } | Select-Object -First 1
    $filesToProcess = @()
    
    if ($readmeFile) {
        $filesToProcess += $readmeFile
        $files = $files | Where-Object { $_.FullName -ne $readmeFile.FullName }
    }
    
    # Add the rest of the files
    $filesToProcess += $files
    
    # Process each file
    $processedCount = 0
    $totalSize = 0

    foreach ($file in $filesToProcess) {
        $processedCount++
        $relativePath = $file.FullName.Substring($Directory.Path.Length).TrimStart("\")
        $fileSize = $file.Length
        $totalSize += $fileSize

        Write-Progress -Activity "Merging Files" -Status "Processing file $processedCount of $fileCount" -PercentComplete (($processedCount / $fileCount) * 100)
        
        # Add file header with name and separator
        Add-Content -Path $OutputFile -Value "FILE: $relativePath" -Encoding UTF8
        Add-Content -Path $OutputFile -Value ($("-") * 80) -Encoding UTF8
        
        # Add file content
        try {
            $fileContent = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
            Add-Content -Path $OutputFile -Value $fileContent -Encoding UTF8
        }
        catch {
            Add-Content -Path $OutputFile -Value "[ERROR: Could not read file content]" -Encoding UTF8
            Write-Warning "Could not read content from file '$($file.FullName)': $_"
        }
        
        # Add spacing between files
        Add-Content -Path $OutputFile -Value "`n`n" -Encoding UTF8
        Add-Content -Path $OutputFile -Value ($("=") * 80) -Encoding UTF8
        Add-Content -Path $OutputFile -Value "`n`n" -Encoding UTF8
    }

    Write-Progress -Activity "Merging Files" -Completed
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    
    Write-Host "Merge completed successfully!" -ForegroundColor Green
    Write-Host "Processed $processedCount files ($totalSizeMB MB)" -ForegroundColor Green
    Write-Host "Output file: $OutputFile" -ForegroundColor Green
}

# Main execution
Write-Host "Starting file merge process..." -ForegroundColor Yellow
Merge-Files -Directory $InputDirectory -OutputFile $OutputFile -Recursive $Recurse -ExcludeExts $ExcludeExtensions -ExcludeFilesList $ExcludeFiles
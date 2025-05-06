# browser.ps1
# Opens a URL in the default web browser

function browser {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Url
    )
    
    Write-Host "Opening browser: " -NoNewline -ForegroundColor Cyan
    
    # Check if URL has a scheme, add https:// if not
    if (-not ($Url -match "^[a-z]+://")) {
        Write-Host "Adding https:// prefix" -ForegroundColor Yellow
        $Url = "https://$Url"
    }
    
    Write-Host $Url -ForegroundColor Green
    
    try {
        # Open the URL in the default browser
        Start-Process $Url
        return $true
    }
    catch {
        Write-Host "Error opening URL: $_" -ForegroundColor Red
        return $false
    }
}

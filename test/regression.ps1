#tests stuff
#TODO: add pester later
param(
    [Parameter(Position = 0)]
    [string]$TestGroup = "all"
)

# Global test results tracking
$global:TestResults = @{
    Passed = @()
    Failed = @()
}

# Function to handle errors consistently
function Write-Error {
    param(
        [string]$Command,
        [string]$Errorz
    )
    Write-Host "Error in '$Command' command: $Errorz" -ForegroundColor Red
    $global:TestResults.Failed += $Command
}

# Function to track successful tests
function Write-Success {
    param(
        [string]$Command
    )
    $global:TestResults.Passed += $Command
}

# Test functions
function Test-All {
    try {
        & all
        Write-Success "all"
    }
    catch {
        Write-Error "all" $_
    }
}

function Test-My {
    try {
        & all my
        Write-Success "all my"
    }
    catch {
        Write-Error "all my" $_
    }
}

function Test-Homies {
    try {
        & all my homies
        Write-Success "all my homies"
    }
    catch {
        Write-Error "all my homies" $_
    }
}

function Test-Hate {
    try {
        & all my homies hate
        Write-Success "all my homies hate"
    }
    catch {
        Write-Error "all my homies hate" $_
    }
}

function Test-Windows {
    try {
        & all my homies hate windows
        Write-Success "all my homies hate windows"
    }
    catch {
        Write-Error "all my homies hate windows" $_
    }
}

function Test-Clock {
    try {
        & all my clock start
        Write-Success "all my clock start"
    }
    catch {
        Write-Error "all my clock start" $_
    }
    
    try {
        & all my clock stop
        Write-Success "all my clock stop"
    }
    catch {
        Write-Error "all my clock stop" $_
    }
}

function Test-Browser {
    try {
        & all my browser google.com
        Write-Success "all my browser google.com"
    }
    catch {
        Write-Error "all my browser google.com" $_
    }
}

function Test-Files {
    try {
        & all my files
        Write-Success "all my files"
    }
    catch {
        Write-Error "all my files" $_
    }
}

function Test-Shell {
    try {
        & all my shell
        Write-Success "all my shell"
    }
    catch {
        Write-Error "all my shell" $_
    }
}

function Test-Install {
    try {
        & all my homies install
        Write-Success "all my homies install"
    }
    catch {
        Write-Error "all my homies install" $_
    }
    
    try {
        $result = & all my homies install chocolatey
        if (-not $result.ok) {
            throw $result.error
        }
        else {
            Write-Success "all my homies install chocolatey"
        }
    }
    catch {
        Write-Error "all my homies install chocolatey" $_
    }
}

function Test-Json {
    try {
        & all my homies hate json
        Write-Success "all my homies hate json"
    }
    catch {
        Write-Error "all my homies hate json" $_
    }
    
    try {
        & all my homies hate json view "https://fakestoreapi.com/products/1"
        Write-Success "all my homies hate json view"
    }
    catch {
        Write-Error "all my homies hate json view" $_
    }
    
    try {
        & all my homies hate json tree "https://jsonplaceholder.typicode.com/users"
        Write-Success "all my homies hate json tree"
    }
    catch {
        Write-Error "all my homies hate json tree" $_
    }
    
    try {
        & all my homies hate json table "https://jsonplaceholder.typicode.com/users"
        Write-Success "all my homies hate json table"
    }
    catch {
        Write-Error "all my homies hate json table" $_
    }
    
    try {
        & all my homies hate json highlight '{"name":"John","age":30,"city":"New York"}'
        Write-Success "all my homies hate json highlight"
    }
    catch {
        Write-Error "all my homies hate json highlight" $_
    }
    
    try {
        & all my homies hate json chart '{   "sales": [     { "month": "January", "value": 120 },     { "month": "February", "value": 150 },     { "month": "March", "value": 200 },     { "month": "April", "value": 180 },     { "month": "May", "value": 250 }   ] }' "sales" "month" "value" 
        & all my homies hate json chart '{
    "dns_speeds":  [
                       {
                           "speed": 45.1,
                           "provider": "Cloudflare Public DNS (with malware blocklist)"
                       },
                       {
                           "speed": 56,
                           "provider": "Cloudflare Public DNS (USA, standard)"
                       },
                       {
                           "speed": 104,
                           "provider": "CleanBrowsing"
                       },
                       {
                           "speed": 122.7,
                           "provider": "AdGuard DNS (Cyprus)"
                       }
                   ]
}' "dns_speeds" "provider" "speed" 
        Write-Success "all my homies hate json chart"
    }
    catch {
        Write-Error "all my homies hate json chart" $_
    }
}

function Test-Download {
    try {
        $tempFile = Join-Path $env:TEMP "ProFont.zip"
        $result = & all my homies download "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/ProFont.zip" $tempFile
        if (-not $result.ok) {
            throw $result.error
        }
        else {
            Write-Success "all my homies hate download"
        }
    }
    catch {
        Write-Error "all my homies hate download" $_
    }
}

function Test-Fetch {
    try {
        $result = & all my homies hate fetch "https://fakestoreapi.com/products/1"
        if (-not $result.ok) {
            throw $result.error
        }
        else {
            Write-Success "all my homies hate fetch"
        }
    }
    catch {
        Write-Error "all my homies hate fetch" $_
    }
}

# Main test execution
switch ($TestGroup.ToLower()) {
    "all" {
        Test-All
        Test-My
        Test-Homies
        Test-Hate
        Test-Windows
        Test-Clock
        Test-Files
        Test-Shell
        Test-Browser
        Test-Json
        Test-Install
        Test-Download
        Test-Fetch
    }
    "my" {
        Test-Files
        Test-Shell
        Test-Browser
    }
    "clock" {
        Test-Clock
    }
    "json" {
        Test-Json
    }
    "install" {
        Test-Install
    }
    "download" {
        Test-Download
    }
    "fetch" {
        Test-Fetch
    }
    default {
        Write-Host "Unknown test group: $TestGroup" -ForegroundColor Yellow
        Write-Host "Available test groups: all, my, clock, json, install" -ForegroundColor Yellow
    }
}

# Display test results summary
Write-Host "`nTest Results Summary:" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "Total Tests Run: $($global:TestResults.Passed.Count + $global:TestResults.Failed.Count)" -ForegroundColor White
Write-Host "Passed: $($global:TestResults.Passed.Count)" -ForegroundColor Green
Write-Host "Failed: $($global:TestResults.Failed.Count)" -ForegroundColor Red

if ($global:TestResults.Failed.Count -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $global:TestResults.Failed | ForEach-Object {
        Write-Host "- $_" -ForegroundColor Red
    }
}

if ($global:TestResults.Passed.Count -gt 0) {
    Write-Host "`nPassed Tests:" -ForegroundColor Green
    $global:TestResults.Passed | ForEach-Object {
        Write-Host "- $_" -ForegroundColor Green
    }
}

#https://fakestoreapi.com/products/1
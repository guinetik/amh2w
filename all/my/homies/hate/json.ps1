# all/my/homies/hate/json.ps1

# Pretty print a JSON file
#all my homies hate json view "C:\path\to\data.json"

# Show a JSON URL response as a tree
#all my homies hate json tree "https://jsonplaceholder.typicode.com/users"

# Display JSON data as a table
#all my homies hate json table "https://jsonplaceholder.typicode.com/users"

# Interactively explore a complex JSON structure
#all my homies hate json explore "https://jsonplaceholder.typicode.com/users"

# Create a bar chart from JSON data specifying key and value properties
#all my homies hate json chart "https://api.example.com/stats" "name" "count"

# Apply syntax highlighting to a JSON string
#all my homies hate json highlight '{"name":"John","age":30,"city":"New York"}'

param(
    [Parameter(Position = 0)]
    [ValidateSet("view", "tree", "table", "explore", "chart", "highlight")]
    [string]$Action,
    
    [Parameter(Position = 1)]
    [string]$InputData,
    
    [Parameter(Position = 2)]
    [string]$KeyProperty = "",
    
    [Parameter(Position = 3)]
    [string]$ValueProperty = "",
    
    [Parameter()]
    [int]$MaxWidth = 50,
    
    [Parameter()]
    [int]$MaxDepth = 10,
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

# Use AMH2W_HOME environment variable for path resolution
if (-not $env:AMH2W_HOME) {
    Write-Error "AMH2W_HOME environment variable is not set. Please run setup.ps1 first."
    exit 1
}

$CorePath = Join-Path -Path $env:AMH2W_HOME -ChildPath "core"

# Import core utilities
. "$CorePath\result.ps1"
. "$CorePath\pipeline.ps1"
. "$CorePath\log.ps1"

$Context = New-PipelineContext

function Convert-InputToJson {
    param(
        [string]$InputData
    )
    
    # If input starts with { or [, treat as JSON string
    if ($InputData.Trim().StartsWith("{") -or $InputData.Trim().StartsWith("[")) {
        try {
            $jsonObject = $InputData | ConvertFrom-Json
            return $jsonObject
        }
        catch {
            Log error "Failed to parse input as JSON: $_" $Context
            return $null
        }
    }
    
    # If input is a file path, try to read it
    if (Test-Path $InputData) {
        try {
            $content = Get-Content $InputData -Raw
            $jsonObject = $content | ConvertFrom-Json
            return $jsonObject
        }
        catch {
            Log error "Failed to parse file content as JSON: $_" $Context
            return $null
        }
    }
    
    # Otherwise, treat as URL and try to fetch it
    try {
        $response = Invoke-WebRequest -Uri $InputData -UseBasicParsing
        $jsonObject = $response.Content | ConvertFrom-Json
        return $jsonObject
    }
    catch {
        Log error "Failed to fetch or parse URL content as JSON: $_" $Context
        return $null
    }
}

# Pretty Print JSON with color formatting
function Format-Json {
    param(
        [Parameter(Mandatory = $true)]
        [object]$JsonObject,
        
        [Parameter()]
        [int]$Depth = 10
    )
    
    $formattedJson = $JsonObject | ConvertTo-Json -Depth $Depth -Compress:$false
    
    # Use PowerShell's built-in colorization if available (PowerShell 7+)
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $formattedJson | Out-String | Write-Host
    }
    else {
        # Add indentation for better readability in earlier PowerShell versions
        $formattedJson -split "`n" | ForEach-Object { 
            if ($_ -match '^\s*"[^"]+"\s*:') {
                # Property names in cyan
                $line = $_ -replace '("([^"]+)")\s*:', '$1:'
                $line = $line -replace '("([^"]+)"):(.*)$', "`e[36m`$1`e[0m:`$3"
                Write-Host $line
            }
            elseif ($_ -match ':\s*"[^"]+"') {
                # String values in green
                $line = $_ -replace '(.+):\s*("([^"]+)")(.*)$', "`$1: `e[32m`$2`e[0m`$4"
                Write-Host $line
            }
            elseif ($_ -match ':\s*\d+') {
                # Numeric values in yellow
                $line = $_ -replace '(.+):\s*(\d+)(.*)$', "`$1: `e[33m`$2`e[0m`$3"
                Write-Host $line
            }
            elseif ($_ -match ':\s*(true|false)') {
                # Boolean values in magenta
                $line = $_ -replace '(.+):\s*(true|false)(.*)$', "`$1: `e[35m`$2`e[0m`$3"
                Write-Host $line
            }
            elseif ($_ -match ':\s*null') {
                # Null values in dark gray
                $line = $_ -replace '(.+):\s*(null)(.*)$', "`$1: `e[90m`$2`e[0m`$3"
                Write-Host $line
            }
            else {
                # Other content in default color
                Write-Host $_
            }
        }
    }
}

# Tree-like structure visualization
function Show-JsonTree {
    param(
        [Parameter(Mandatory = $true)]
        [object]$JsonObject,
        
        [string]$Indent = "",
        [int]$MaxDepth = 10,
        [int]$CurrentDepth = 0
    )
    
    if ($CurrentDepth -ge $MaxDepth) {
        Write-Host "${Indent}└─ ..." -ForegroundColor DarkGray
        return
    }
    
    if ($null -eq $JsonObject) {
        Write-Host "${Indent}└─ null" -ForegroundColor DarkGray
        return
    }
    
    $objectType = $JsonObject.GetType().Name
    
    if ($objectType -eq "PSCustomObject") {
        $properties = $JsonObject.PSObject.Properties
        $count = 0
        foreach ($property in $properties) {
            $count++
            $isLast = $count -eq $properties.Count
            $prefix = if ($isLast) { "└─" } else { "├─" }
            $childIndent = if ($isLast) { "$Indent  " } else { "$Indent│ " }
            
            # Display property name with appropriate color
            Write-Host "$Indent$prefix " -NoNewline -ForegroundColor Gray
            Write-Host "$($property.Name): " -NoNewline -ForegroundColor Cyan
            
            # Recursively process property value
            $value = $property.Value
            if ($null -eq $value) {
                Write-Host "null" -ForegroundColor DarkGray
            }
            elseif ($value -is [string] -or $value -is [int] -or $value -is [bool] -or $value -is [double]) {
                # Format different data types with different colors
                if ($value -is [string]) {
                    Write-Host "`"$value`"" -ForegroundColor Green
                }
                elseif ($value -is [int] -or $value -is [double]) {
                    Write-Host "$value" -ForegroundColor Yellow
                }
                elseif ($value -is [bool]) {
                    Write-Host "$value" -ForegroundColor Magenta
                }
            }
            else {
                # For objects/arrays, just show a newline and recurse
                Write-Host ""
                Show-JsonTree -JsonObject $value -Indent $childIndent -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
            }
        }
    }
    elseif ($objectType -eq "Object[]" -or $JsonObject -is [System.Collections.ArrayList]) {
        $count = 0
        foreach ($item in $JsonObject) {
            $count++
            $isLast = $count -eq $JsonObject.Count
            $prefix = if ($isLast) { "└─" } else { "├─" }
            $childIndent = if ($isLast) { "$Indent  " } else { "$Indent│ " }
            
            # Display array index
            Write-Host "$Indent$prefix [$($count - 1)]" -ForegroundColor Gray
            
            # Recursively process array item
            Show-JsonTree -JsonObject $item -Indent $childIndent -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
        }
    }
    else {
        # Simple value
        Write-Host "$JsonObject" -ForegroundColor White
    }
}

# Table-style visualization for collections
function Show-JsonTable {
    param(
        [Parameter(Mandatory = $true)]
        [object]$JsonObject
    )
    
    if ($null -eq $JsonObject) {
        Write-Host "Input is null, cannot display as table." -ForegroundColor Red
        return
    }
    
    $objectType = $JsonObject.GetType().Name
    
    if ($objectType -eq "Object[]" -or $JsonObject -is [System.Collections.ArrayList]) {
        # Check if array items have similar structure (for table display)
        if ($JsonObject.Count -gt 0) {
            $sampleItem = $JsonObject[0]
            if ($null -ne $sampleItem -and $sampleItem.GetType().Name -eq "PSCustomObject") {
                # Convert to PowerShell objects and display as table
                Write-Host "JSON Data (Table View):" -ForegroundColor Cyan
                $JsonObject | Format-Table -AutoSize | Out-String | Write-Host
                return $true
            }
        }
    }
    elseif ($objectType -eq "PSCustomObject") {
        # Convert single object to array with one element
        $array = @($JsonObject)
        Write-Host "JSON Data (Table View):" -ForegroundColor Cyan
        $array | Format-Table -AutoSize | Out-String | Write-Host
        return $true
    }
    
    Write-Host "The JSON structure is not suitable for table display." -ForegroundColor Yellow
    return $false
}

# Interactive JSON Explorer
function Invoke-JsonExplorer {
    param(
        [Parameter(Mandatory = $true)]
        [object]$JsonObject,
        
        [string]$Path = "root"
    )
    
    Clear-Host
    Write-Host "JSON Explorer - $Path" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    $options = @()
    
    if ($JsonObject -is [PSCustomObject]) {
        $properties = $JsonObject.PSObject.Properties
        foreach ($property in $properties) {
            $options += @{
                Name  = $property.Name
                Value = $property.Value
                Type  = if ($null -ne $property.Value) { $property.Value.GetType().Name } else { "null" }
            }
        }
    }
    elseif ($JsonObject -is [array] -or $JsonObject -is [System.Collections.ArrayList] -or $JsonObject.GetType().Name -match "Object\[\]") {
        for ($i = 0; $i -lt [Math]::Min($JsonObject.Count, 20); $i++) {
            $options += @{
                Name  = "[$i]"
                Value = $JsonObject[$i]
                Type  = if ($null -ne $JsonObject[$i]) { $JsonObject[$i].GetType().Name } else { "null" }
            }
        }
        
        if ($JsonObject.Count -gt 20) {
            $options += @{
                Name  = "... (more items)"
                Value = $null
                Type  = "info"
            }
        }
    }
    else {
        Write-Host "Value: $JsonObject" -ForegroundColor White
        Write-Host "Type: $($JsonObject.GetType().Name)" -ForegroundColor Gray
        Write-Host "----------------------------------------" -ForegroundColor Gray
        Write-Host "Press any key to go back..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Display options
    for ($i = 0; $i -lt $options.Count; $i++) {
        $option = $options[$i]
        $typeColor = switch ($option.Type) {
            "PSCustomObject" { "Magenta" }
            { $_ -match "Object\[\]" -or $_ -match "List" } { "Yellow" }
            "String" { "Green" }
            "Int32" { "Cyan" }
            "Boolean" { "Red" }
            default { "White" }
        }
        
        Write-Host "$($i + 1). " -NoNewline -ForegroundColor Gray
        Write-Host "$($option.Name)" -NoNewline -ForegroundColor White
        Write-Host " : " -NoNewline -ForegroundColor Gray
        Write-Host "($($option.Type))" -ForegroundColor $typeColor
    }
    
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host "B. Go back" -ForegroundColor Yellow
    Write-Host "Q. Quit explorer" -ForegroundColor Red
    
    $choice = Read-Host "Enter your choice"
    
    if ($choice -eq "B" -or $choice -eq "b") {
        return
    }
    elseif ($choice -eq "Q" -or $choice -eq "q") {
        return $true # Signal to completely exit
    }
    elseif ($choice -match "^\d+$" -and [int]$choice -ge 1 -and [int]$choice -le $options.Count) {
        $selectedOption = $options[[int]$choice - 1]
        $shouldExit = Invoke-JsonExplorer -JsonObject $selectedOption.Value -Path "$Path.$($selectedOption.Name)"
        
        if ($shouldExit) {
            return $true
        }
    }
    
    # Recall current explorer after returning from sub-item
    Invoke-JsonExplorer -JsonObject $JsonObject -Path $Path
}

# Chart visualization for numeric data
function Show-JsonBarChart {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Data,
        
        [string]$KeyProperty,
        [string]$ValueProperty,
        [int]$MaxWidth = 50
    )
    
    if ($null -eq $Data) {
        Write-Host "Data is null, cannot visualize as chart." -ForegroundColor Red
        return $false
    }
    
    # Handle single objects vs arrays
    $dataArray = if ($Data -is [array] -or $Data -is [System.Collections.ArrayList]) {
        $Data
    }
    else {
        @($Data)
    }
    
    # If key/value properties aren't specified and it's an object with just two properties,
    # try to use those as key and value
    if ([string]::IsNullOrEmpty($KeyProperty) -and [string]::IsNullOrEmpty($ValueProperty)) {
        if ($dataArray.Count -gt 0 -and $dataArray[0] -is [PSCustomObject]) {
            $props = $dataArray[0].PSObject.Properties
            if ($props.Count -eq 2) {
                $KeyProperty = $props[0].Name
                $ValueProperty = $props[1].Name
                Log info "Auto-detected key property '$KeyProperty' and value property '$ValueProperty'" $Context
            }
        }
    }
    
    # Extract the data to plot
    $chartData = @()
    
    # If key/value properties are specified, extract them
    if (-not [string]::IsNullOrEmpty($KeyProperty) -and -not [string]::IsNullOrEmpty($ValueProperty)) {
        foreach ($item in $dataArray) {
            if ($item -is [PSCustomObject]) {
                $key = $item.$KeyProperty
                $value = $item.$ValueProperty
                
                if ($null -ne $key -and $null -ne $value -and $value -is [ValueType]) {
                    $chartData += @{
                        Key   = $key
                        Value = [double]$value
                    }
                }
            }
        }
    } 
    # Otherwise try to interpret the data as a direct key/value mapping
    else {
        # Handle object with properties as key/value pairs
        if ($dataArray.Count -eq 1 -and $dataArray[0] -is [PSCustomObject]) {
            $obj = $dataArray[0]
            $props = $obj.PSObject.Properties
            
            foreach ($prop in $props) {
                $value = $prop.Value
                if ($value -is [ValueType]) {
                    $chartData += @{
                        Key   = $prop.Name
                        Value = [double]$value
                    }
                }
            }
        }
    }
    
    if ($chartData.Count -eq 0) {
        Write-Host "No chartable data found." -ForegroundColor Yellow
        return $false
    }
    
    # Find the maximum value for scaling
    $maxValue = ($chartData | Measure-Object -Property Value -Maximum).Maximum
    
    Write-Host "Chart Visualization:" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    foreach ($item in $chartData) {
        $barLength = [Math]::Ceiling(($item.Value / $maxValue) * $MaxWidth)
        $bar = "█" * $barLength
        
        # Display the item
        Write-Host "$($item.Key): " -NoNewline -ForegroundColor White
        Write-Host "$bar" -NoNewline -ForegroundColor Cyan
        Write-Host " $($item.Value)" -ForegroundColor Yellow
    }
    
    return $true
}

# Syntax highlighting with tags
function Format-JsonWithTags {
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonString
    )
    
    $result = $JsonString
    
    # Add highlighting for different elements
    $result = $result -replace '(\"[^\"]+\")\s*:', '<keyword>$1</keyword>:' # Property names
    $result = $result -replace ':\s*(\"[^\"]+\")', ': <string>$1</string>' # String values
    $result = $result -replace ':\s*(\d+)', ': <number>$1</number>' # Number values
    $result = $result -replace ':\s*(true|false)', ': <boolean>$1</boolean>' # Boolean values
    $result = $result -replace ':\s*(null)', ': <null>$1</null>' # Null values
    
    # Display with colors
    $result = $result -replace '<keyword>(.*?)</keyword>', $([char]27 + '[36m$1' + [char]27 + '[0m') # Cyan
    $result = $result -replace '<string>(.*?)</string>', $([char]27 + '[32m$1' + [char]27 + '[0m') # Green
    $result = $result -replace '<number>(.*?)</number>', $([char]27 + '[33m$1' + [char]27 + '[0m') # Yellow
    $result = $result -replace '<boolean>(.*?)</boolean>', $([char]27 + '[35m$1' + [char]27 + '[0m') # Magenta
    $result = $result -replace '<null>(.*?)</null>', $([char]27 + '[90m$1' + [char]27 + '[0m') # Gray
    
    return $result
}

function json {
    # Main execution
    Log info "Processing JSON with action: $Action" $Context
    # Convert input to JSON
    $jsonObject = Convert-InputToJson -InputData $InputData
    if ($null -eq $jsonObject) {
        exit 1
    }

    $result = $false

    # Process the action
    switch ($Action) {
        "view" {
            Format-Json -JsonObject $jsonObject -Depth $MaxDepth
            $result = $true
        }
        "tree" {
            Show-JsonTree -JsonObject $jsonObject -MaxDepth $MaxDepth
            $result = $true
        }
        "table" {
            $result = Show-JsonTable -JsonObject $jsonObject
        }
        "explore" {
            Invoke-JsonExplorer -JsonObject $jsonObject
            $result = $true
        }
        "chart" {
            $result = Show-JsonBarChart -Data $jsonObject -KeyProperty $KeyProperty -ValueProperty $ValueProperty -MaxWidth $MaxWidth
        }
        "highlight" {
            $jsonString = $jsonObject | ConvertTo-Json -Depth $MaxDepth
            $highlighted = Format-JsonWithTags -JsonString $jsonString
            Write-Host $highlighted
            $result = $true
        }
    }

    if ($result) {
        return Ok "JSON processed successfully with action: $Action"
    }
    else {
        return Err "Failed to process JSON with action: $Action"
    }
}

# Only run main if this script is NOT being dot-sourced
if ($Action) {
    json
}
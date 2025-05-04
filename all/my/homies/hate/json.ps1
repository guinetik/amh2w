# all/my/homies/hate/json.ps1
# JSON handling utilities with various visualization options

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

function json {
    [CmdletBinding()]
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

    try {
        Log-Info "Processing JSON with action: $Action"
        
        # Check if Action is empty or null
        if ([string]::IsNullOrEmpty($Action)) {
            Log-Info "No action specified. Available actions: view, tree, table, explore, chart, highlight"
            return Ok -Value $null -Message "No action specified. Please specify an action."
        }
        
        # Check if InputData is empty or null
        if ([string]::IsNullOrEmpty($InputData)) {
            Log-Error "No input data specified"
            return Err "No input data specified. Please provide a JSON string, file path, or URL."
        }
        
        # Convert input to JSON
        $jsonObject = Convert-InputToJson -InputData $InputData
        if ($null -eq $jsonObject) {
            return Err "Failed to parse or retrieve JSON from input: $InputData"
        }

        # Process the action
        switch ($Action) {
            "view" {
                Format-Json -JsonObject $jsonObject -Depth $MaxDepth
                return Ok -Value $jsonObject -Message "JSON viewed successfully"
            }
            "tree" {
                Show-JsonTree -JsonObject $jsonObject -MaxDepth $MaxDepth
                return Ok -Value $jsonObject -Message "JSON tree displayed successfully"
            }
            "table" {
                $result = Show-JsonTable -JsonObject $jsonObject
                if ($result) {
                    return Ok -Value $jsonObject -Message "JSON table displayed successfully"
                } else {
                    return Err "Failed to display JSON as table - structure may not be suitable"
                }
            }
            "explore" {
                $result = Invoke-JsonExplorer -JsonObject $jsonObject
                return Ok -Value $jsonObject -Message "JSON explorer completed successfully"
            }
            "chart" {
                $result = Show-JsonBarChart -Data $jsonObject -KeyProperty $KeyProperty -ValueProperty $ValueProperty -MaxWidth $MaxWidth
                if ($result) {
                    return Ok -Value $jsonObject -Message "JSON chart displayed successfully"
                } else {
                    return Err "Failed to create chart from JSON - structure may not be suitable"
                }
            }
            "highlight" {
                Format-JsonWithTags -JsonObject $jsonObject -Depth $MaxDepth
                return Ok -Value $jsonObject -Message "JSON highlighted successfully"
            }
            default {
                return Err "Unknown JSON action: $Action. Valid actions are: view, tree, table, explore, chart, highlight"
            }
        }
    }
    catch {
        Log-Error "Error processing JSON: $_"
        return Err "Error processing JSON: $_"
    }
}

function Convert-InputToJson {
    param(
        [string]$InputData
    )
    
    Log-Debug "Attempting to convert input to JSON: $InputData"
    
    # If input starts with { or [, treat as JSON string
    if ($InputData.Trim().StartsWith("{") -or $InputData.Trim().StartsWith("[")) {
        try {
            Log-Debug "Input appears to be a JSON string, parsing directly..."
            $jsonObject = $InputData | ConvertFrom-Json
            Log-Debug "Successfully parsed JSON string"
            return $jsonObject
        }
        catch {
            Log-Error "Failed to parse input as JSON: $_"
            return $null
        }
    }
    
    # If input is a file path, try to read it
    if (Test-Path $InputData) {
        try {
            Log-Debug "Input appears to be a file path, reading content..."
            $content = Get-Content $InputData -Raw
            $jsonObject = $content | ConvertFrom-Json
            Log-Debug "Successfully parsed JSON from file"
            return $jsonObject
        }
        catch {
            Log-Error "Failed to parse file content as JSON: $_"
            return $null
        }
    }
    
    # Otherwise, treat as URL and try to fetch it
    try {
        Log-Debug "Input appears to be a URL, fetching content..."
        $response = Invoke-WebRequest -Uri $InputData -UseBasicParsing
        $jsonObject = $response.Content | ConvertFrom-Json
        Log-Debug "Successfully parsed JSON from URL"
        return $jsonObject
    }
    catch {
        Log-Error "Failed to fetch or parse URL content as JSON: $_"
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
    
    try {
        Log-Debug "Formatting JSON with depth $Depth"
        $formattedJson = $JsonObject | ConvertTo-Json -Depth $Depth -Compress:$false
        
        # Use PowerShell's built-in colorization if available (PowerShell 7+)
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $formattedJson | Out-String | ForEach-Object {
                Write-Host $_
            }
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
        
        return $true
    }
    catch {
        Log-Error "Error formatting JSON: $_"
        return $false
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
    
    try {
        Log-Debug "Showing JSON tree with max depth $MaxDepth (current depth: $CurrentDepth)"
        
        if ($CurrentDepth -ge $MaxDepth) {
            Write-Host "${Indent}└─ ..." -ForegroundColor DarkGray
            return $true
        }
        
        if ($null -eq $JsonObject) {
            Write-Host "${Indent}└─ null" -ForegroundColor DarkGray
            return $true
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
                    $result = Show-JsonTree -JsonObject $value -Indent $childIndent -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                    if (-not $result) {
                        return $false
                    }
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
                $result = Show-JsonTree -JsonObject $item -Indent $childIndent -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                if (-not $result) {
                    return $false
                }
            }
        }
        else {
            # Simple value
            Write-Host "$JsonObject" -ForegroundColor White
        }
        
        return $true
    }
    catch {
        Log-Error "Error displaying JSON tree: $_"
        return $false
    }
}

# Table-style visualization for collections
function Show-JsonTable {
    param(
        [Parameter(Mandatory = $true)]
        [object]$JsonObject
    )
    
    try {
        Log-Debug "Attempting to display JSON as table"
        
        if ($null -eq $JsonObject) {
            Log-Warning "Input is null, cannot display as table."
            return $false
        }
        
        $objectType = $JsonObject.GetType().Name
        
        if ($objectType -eq "Object[]" -or $JsonObject -is [System.Collections.ArrayList]) {
            # Check if array items have similar structure (for table display)
            if ($JsonObject.Count -gt 0) {
                $sampleItem = $JsonObject[0]
                if ($null -ne $sampleItem -and $sampleItem.GetType().Name -eq "PSCustomObject") {
                    # Convert to PowerShell objects and display as table
                    Write-Host "JSON Data (Table View):" -ForegroundColor Cyan
                    $tableOutput = $JsonObject | Format-Table -AutoSize | Out-String
                    $tableOutput.Trim().Split("`n") | ForEach-Object {
                        Write-Host $_
                    }
                    return $true
                }
            }
        }
        elseif ($objectType -eq "PSCustomObject") {
            # Convert single object to array with one element
            $array = @($JsonObject)
            Write-Host "JSON Data (Table View):" -ForegroundColor Cyan
            $tableOutput = $array | Format-Table -AutoSize | Out-String
            $tableOutput.Trim().Split("`n") | ForEach-Object {
                Write-Host $_
            }
            return $true
        }
        
        Log-Warning "The JSON structure is not suitable for table display."
        return $false
    }
    catch {
        Log-Error "Error displaying JSON as table: $_"
        return $false
    }
}

# Helper function to format value for display in explorer
function Format-ValueForDisplay {
    param(
        [object]$Value, 
        [int]$MaxLength = 30
    )
    
    if ($null -eq $Value) {
        return "null"
    }
    elseif ($Value -is [string]) {
        # Truncate long strings and add ellipsis
        if ($Value.Length -gt $MaxLength) {
            return "`"$($Value.Substring(0, $MaxLength))...`""
        }
        return "`"$Value`""
    }
    elseif ($Value -is [bool]) {
        return $Value.ToString().ToLower() # Make sure "true" and "false" are lowercase
    }
    elseif ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal]) {
        return $Value.ToString()
    }
    elseif ($Value -is [DateTime]) {
        return $Value.ToString("yyyy-MM-dd HH:mm:ss")
    }
    elseif ($Value -is [array] -or $Value -is [System.Collections.ArrayList]) {
        return "Array[" + $Value.Count + "]"
    }
    elseif ($Value -is [HashTable] -or $Value -is [System.Collections.Specialized.OrderedDictionary]) {
        return "Object{" + $Value.Count + "}"
    }
    elseif ($Value.GetType().Name -eq "PSCustomObject") {
        $propCount = ($Value.PSObject.Properties | Measure-Object).Count
        return "Object{" + $propCount + "}"
    }
    else {
        # Fall back to regular string representation
        $str = $Value.ToString()
        if ($str.Length -gt $MaxLength) {
            return $str.Substring(0, $MaxLength) + "..."
        }
        return $str
    }
}

# Interactive JSON Explorer
function Invoke-JsonExplorer {
    param(
        [Parameter(Mandatory = $true)]
        [object]$JsonObject,
        
        [string]$Path = "root"
    )
    
    try {
        Clear-Host
        Write-Host "JSON Explorer - $Path" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray
        
        $options = @()
        
        if ($JsonObject -is [PSCustomObject]) {
            $properties = $JsonObject.PSObject.Properties
            foreach ($property in $properties) {
                $value = $property.Value
                $isPrimitive = $value -is [string] -or $value -is [int] -or $value -is [bool] -or 
                              $value -is [double] -or $value -is [long] -or $value -is [DateTime] -or
                              $null -eq $value
                
                $options += @{
                    Name       = $property.Name
                    Value      = $value
                    Type       = if ($null -ne $value) { $value.GetType().Name } else { "null" }
                    IsPrimitive = $isPrimitive
                    DisplayValue = if ($isPrimitive) { Format-ValueForDisplay -Value $value } else { $null }
                }
            }
        }
        elseif ($JsonObject -is [array] -or $JsonObject -is [System.Collections.ArrayList] -or $JsonObject.GetType().Name -match "Object\[\]") {
            for ($i = 0; $i -lt [Math]::Min($JsonObject.Count, 20); $i++) {
                $item = $JsonObject[$i]
                $isPrimitive = $item -is [string] -or $item -is [int] -or $item -is [bool] -or 
                              $item -is [double] -or $item -is [long] -or $item -is [DateTime] -or
                              $null -eq $item
                
                $options += @{
                    Name       = "[$i]"
                    Value      = $item
                    Type       = if ($null -ne $item) { $item.GetType().Name } else { "null" }
                    IsPrimitive = $isPrimitive
                    DisplayValue = if ($isPrimitive) { Format-ValueForDisplay -Value $item } else { $null }
                }
            }
            
            if ($JsonObject.Count -gt 20) {
                $options += @{
                    Name        = "... (more items)"
                    Value       = $null
                    Type        = "info"
                    IsPrimitive = $true
                    DisplayValue = "total: $($JsonObject.Count) items"
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
            
            if ($option.IsPrimitive) {
                # If it's a primitive type, show its value
                $valueColor = switch -Regex ($option.Type) {
                    "String" { "Green" }
                    "Int32|Int64|Double|Decimal" { "Yellow" }
                    "Boolean" { "Magenta" }
                    "null" { "DarkGray" }
                    default { "White" }
                }
                
                Write-Host "($($option.Type)) " -NoNewline -ForegroundColor $typeColor
                Write-Host "$($option.DisplayValue)" -ForegroundColor $valueColor
            } else {
                # Otherwise just show its type
                Write-Host "($($option.Type))" -ForegroundColor $typeColor
            }
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
    catch {
        Log-Error "Error in JSON explorer: $_"
        return $true # Signal to exit on error
    }
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
    
    try {
        Log-Debug "Showing JSON bar chart with max width $MaxWidth"
        
        if ($null -eq $Data) {
            Log-Warning "Data is null, cannot visualize as chart."
            return $false
        }
        
        # Extract data to plot
        $chartData = @()
        
        # Check if data is a direct object with a 'sales' property
        if ($Data -is [PSCustomObject] -and $Data.PSObject.Properties['sales']) {
            $salesData = $Data.sales
            
            if ($salesData -is [array] -or $salesData -is [System.Collections.ArrayList]) {
                
                # Process each item to extract chart data
                foreach ($item in $salesData) {
                    if ($item -is [PSCustomObject]) {
                        # Try to get key and value properties
                        $key = if ($item.PSObject.Properties[$KeyProperty]) { $item.$KeyProperty } else { $null }
                        $value = if ($item.PSObject.Properties[$ValueProperty]) { $item.$ValueProperty } else { $null }
                        
                        if ($null -ne $key -and $null -ne $value) {
                            try {
                                $numericValue = [double]$value
                                $chartData += [PSCustomObject]@{
                                    Key   = $key
                                    Value = $numericValue
                                }
                            }
                            catch {
                                Log-Warning "Could not convert '$value' to a number for key '$key'"
                            }
                        }
                    }
                }
            }
        }
        else {
            # If data is already an array, try to use it directly
            if ($Data -is [array] -or $Data -is [System.Collections.ArrayList]) {
                foreach ($item in $Data) {
                    if ($item -is [PSCustomObject]) {
                        # Try to get key and value properties
                        $key = if ($item.PSObject.Properties[$KeyProperty]) { $item.$KeyProperty } else { $null }
                        $value = if ($item.PSObject.Properties[$ValueProperty]) { $item.$ValueProperty } else { $null }
                        
                        if ($null -ne $key -and $null -ne $value) {
                            try {
                                $numericValue = [double]$value
                                $chartData += [PSCustomObject]@{
                                    Key   = $key
                                    Value = $numericValue
                                }
                            }
                            catch {
                                Log-Warning "Could not convert '$value' to a number for key '$key'"
                            }
                        }
                    }
                }
            }
            # If data is a simple object, try to use its properties directly
            elseif ($Data -is [PSCustomObject]) {
                foreach ($prop in $Data.PSObject.Properties) {
                    if ($null -ne $prop.Value) {
                        try {
                            $numericValue = [double]$prop.Value
                            $chartData += [PSCustomObject]@{
                                Key   = $prop.Name
                                Value = $numericValue
                            }
                        }
                        catch {
                            # Not a numeric property, ignore
                        }
                    }
                }
            }
        }
        
        # Check if we found any chartable data
        if ($chartData.Count -eq 0) {
            Log-Warning "No chartable data found. Please check the JSON structure and key/value properties."
            Log-Warning "Try using the 'explore' action first to understand your JSON data structure"
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
    catch {
        Log-Error "Error creating JSON bar chart: $_"
        return $false
    }
}

# Syntax highlighting with tags
function Format-JsonWithTags {
    param(
        [Parameter(Mandatory = $true)]
        [object]$JsonObject,
        
        [Parameter()]
        [int]$Depth = 10
    )
    
    try {
        Log-Debug "Formatting JSON with syntax highlighting"
        
        # Convert to string if it's an object
        $jsonString = if ($JsonObject -is [string]) {
            $JsonObject
        } else {
            $JsonObject | ConvertTo-Json -Depth $Depth
        }
        
        $result = $jsonString
        
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
        
        $result.Split("`n") | ForEach-Object {
            Write-Host $_
        }
        
        return $true
    }
    catch {
        Log-Error "Error highlighting JSON: $_"
        return $false
    }
}

# 🧠 AMH2W Context Transfer Document

Hey future Claude! You're working on AMH2W (All My Homies Handle Windows) - a PowerShell DSL that makes Windows bearable through meme-driven grammar.

## 🎯 Current State
- Core architecture: Result pattern (Ok/Err), no exceptions
- Modules completed: json, iftp, zipping
- Command structure: `all my homies hate [thing] [action] [args...]`

## 🔥 What We Just Built: zipping.ps1
Location: `all/my/homies/hate/zipping.ps1`

Key learnings:
1. **Tool Detection Pattern**: Check for 7-Zip, WinRAR, tar in that order
2. **Result Objects**: Always use `ok`/`error` properties (not Success/Error)
3. **7-Zip Quirks**: For tar.gz, it extracts to temp dir first, then processes whatever file appears
4. **Error Handling**: Use try/finally for cleanup, return Err objects

```powershell
# Working examples:
all my homies hate zipping zip "file.txt" "output.gz" gzip
all my homies hate zipping unzip "archive.tgz"
```

## 📝 Code Patterns to Follow

1. **Module Structure**:
```powershell
function module_name {
    param([string]$Action, [object[]]$Rest)
    
    $result = switch ($Action) {
        "verb" { Do-Something }
    }
    return $result
}

```

2. **Result Pattern**:
```powershell
return Ok -Value "Success message"
return Err "Error message"
```

3. **Logging**:
```powershell
Log-Info "📦 Doing something..."
Log-Error "❌ It broke!"
```

## ⚠️ Watch Out For
- Follow Result pattern for all commands
- Use pipeline for chaining commands `Invoke-Pipeline`
- The human loves emojis in log messages

## 🚀 Next Steps Ideas
- `all my homies hate clipboard` - Clipboard management
- `all my homies hate screenshot` - Screen capture tools  
- `all my homies hate services` - Windows service management
- `all my homies hate registry` - Registry editor wrapper

Remember: The goal is to make Windows operations feel like natural language while secretly being a powerful scripting toolkit. Keep it memetic, keep it functional!

### 📋 Clipboard Module Notes
Location: `all/my/clip/`

**Key Learnings:**
1. **Global State Pattern**: Use `$global:` variables for persistent state across sessions
2. **History Management**: Max 50 items, newest first, with preview truncation
3. **Pipeline Support**: Copy function handles both arguments and pipeline input
4. **Pattern Breaking**: `paste.ps1` deliberately breaks Result pattern (direct output + exit code)

**Implementation Details:**
- `clipboard.ps1`: History management with Add-ClipboardHistory helper function
- `copy.ps1`: Uses Set-Clipboard and automatically adds to history
- `paste.ps1`: Direct output with exit codes (0 for success, 1 for error)

**Code Patterns:**
```powershell
# Global variable initialization
if (-not (Test-Path variable:global:AMH2W_VARIABLE)) {
    $global:AMH2W_VARIABLE = @()
}

# Pipeline input handling in copy
if ($input) {
    $pipelineContent = @()
    $input | ForEach-Object { $pipelineContent += $_ }
    $content = $pipelineContent -join "`n"
}

# Preview truncation pattern
$preview = if ($text.Length -gt 50) { 
    "$($text.Substring(0, 47))..." 
} else { 
    $text 
}
```

### 🎯 Module Creation Checklist
When creating a new module under `all/my/[namespace]`:
1. Create the namespace folder
2. Create the main `[namespace].ps1` file with routing function
3. Add individual command files (e.g., `copy.ps1`, `paste.ps1`)
4. If using global state, initialize it properly with existence checks
5. Export functions explicitly with `Export-ModuleMember`
6. Test pipeline support where appropriate
7. Consider if any commands need to break the Result pattern (like `paste`)

### 🎨 UI/UX Patterns
- Use emojis in log messages (📋 📊 ✅ ❌ 🧹)
- Provide previews for long content (truncate at ~50 chars)
- Use colored output for different message types:
  - `Yellow` for headers/actions
  - `Cyan` for content/data
  - `Green` for success
  - `Red` for errors
- Include usage examples in error messages


### 🔒 Elevation

The framework already has elevation logic in `core/elevation.ps1`. Any script that needs elevation should self check and  use the `Invoke-Elevate` function passing its own command as the first argument then the rest of the arguments. Example:

```powershell
    # Elevate if needed
    if (-not (Test-IsAdmin)) {
        Invoke-Elevate -Command "all my homies install linux '$DistroName'" -Description "Install Linux WSL Distro" -Prompt $true
        return
    }
```

Remember: Keep the meme spirit alive while building genuinely useful tools! 🚀

---

# AMH2W Library Overview

AMH2W (All My Homies Handle Windows) is a PowerShell utility library with a declarative command structure and Rust-like error handling. This library follows a natural language-like command structure with a hierarchical namespace system.

## Key Features

- **Command Chaining**: Natural language-like command structure
- **Result Pattern**: Rust-inspired error handling with `Ok` and `Err` types
- **Pipeline Execution**: Chain operations with proper error handling
- **No Exceptions**: All operations return result objects instead of throwing exceptions
- **Logging System**: Built-in logging functionality for debugging and monitoring

## Command Structure

The library uses a grammar-oriented command structure with nested namespaces:

```
all my homies hate [namespace] [command] [arguments...]
```

Namespaces:
- `all`: Root namespace, contains everything
- `my`: User-specific commands
- `homies`: Tools, utilities, and contacts
- `hate`: Makes unwieldy commands easier to use
- `windows`: Windows-specific commands

## Code Architecture

1. **Result Pattern**: Functions return `Ok` or `Err` objects:
   ```powershell
   return Ok -Value $data -Message "Operation succeeded"
   return Err "Something went wrong"
   ```

2. **Logging**: Use the logging system instead of `Write-Host` for system messages:
   ```powershell
   Log-Info "Operation started"
   Log-Warning "Potential issue detected"
   Log-Error "Operation failed"
   ```
   
   Use `Write-Host` for user-facing output where formatting matters (e.g., JSON visualization).

3. **Command Structure**: Functions should follow the pattern in `uptime.ps1` and `json.ps1`

## JSON Command Examples

The `json` module provides various ways to work with JSON:

```powershell
# Pretty print a JSON file
all my homies hate json view "C:\path\to\data.json"

# Show a JSON URL response as a tree
all my homies hate json tree "https://jsonplaceholder.typicode.com/users"

# Display JSON data as a table
all my homies hate json table "https://jsonplaceholder.typicode.com/users"

# Interactively explore a complex JSON structure
all my homies hate json explore "https://jsonplaceholder.typicode.com/users" 

# Create a bar chart from JSON data using key/value properties
all my homies hate json chart "test.json" "month" "value"

# Apply syntax highlighting to a JSON string
all my homies hate json highlight '{"name":"John","age":30,"city":"New York"}'
```

## Development Guidelines

1. Use the Result API: Always return `Ok` or `Err` objects from main command functions (D:\Developer\amh2w\core\result.ps1)
2. Use logging for system messages: Use the logging system for diagnostic info (D:\Developer\amh2w\core\logging.ps1)
3. Use `Write-Host` for user-facing content: Direct console output for formatted visualizations
4. Proper error handling: Always catch and handle errors, returning appropriate `Err` objects.
5. Chain commands using the pipeline. 
   ```powershell
   # Install modules
        $modulesResult = Invoke-Pipeline -Steps @(
            { Install-PSModule -ModuleName "PSReadLine" }
            { Install-PSModule -ModuleName "Terminal-Icons" }
        ) -PipelineName "PowerShell Module Installation"
   ```
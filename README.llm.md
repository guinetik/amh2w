
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
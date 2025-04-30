# AMH2W - All My Homies Handle Windows

A PowerShell utility library with a declarative command structure and Rust-like error handling.

## Features

- **Command Chaining**: Use a natural language-like command structure
- **Result Pattern**: Rust-inspired error handling with `Ok` and `Err` types
- **Pipeline Execution**: Chain operations with proper error handling
- **No Exceptions**: All operations return result objects instead of throwing exceptions
- **Logging System**: Built-in logging functionality for debugging and monitoring
- **Modular Core**: Core functionality separated into reusable components

## Installation

1. Clone this repository:
```powershell
git clone https://github.com/yourusername/AMH2W.git
cd AMH2W
```

2. Run the setup script:
```powershell
.\setup.ps1
```

3. Restart your PowerShell session or reload your profile:
```powershell
. $PROFILE
```

## Usage

### Basic Usage

The library uses a grammar oriented command structure:

```powershell
# Basic command chain
all my homies

# Access specific namespaces
all my homies hate windows
all my homies hate json

# Utility commands
all my clock start
all my uptime

# Fetch data
all my homies fetch "https://fakestoreapi.com/products/1"
```

## Command Namespaces

Commands are organized into namespaces which can be accessed using the grammar chain. I will try to explain conceptually where this idea came from.

### ALL

The `all` namespace is the root namespace and contains the core commands. So it contains everything.

### MY

The `my` namespace is the next level of commands. It contains commands that are specific to the user.

### HOMIES

The `homies` namespace is the next level of commands. It contains commands that are specific to tools, utilities and contacts.

### HATE

The `hate` namespace is the next level of commands. The idea is to make unwieldy commands easier to use.

### WINDOWS

The `windows` namespace is the next level of commands. It contains commands that are specific to Windows for optimization, cleanup, telemetry, etc.

```powershell
# Windows management
all my homies hate windows

# JSON operations
all my homies hate json tree "https://jsonplaceholder.typicode.com/users"

# System utilities
all my clock start
all my uptime
```

### Available Commands

#### System Utilities
- `all my clock start`: Start system clock monitoring
- `all my uptime`: Check system uptime

#### Data Operations
- `all my homies fetch [url]`: Fetch data from a URL
- `all my homies hate json tree [url]`: Display JSON data in a tree structure

#### Windows Management
- `all my homies hate windows`: Access Windows management commands

## Project Structure

The library uses a modular structure with core functionality and command implementations:

```
├───core/                # Core functionality
│   ├───import.ps1       # Module imports and initialization
│   ├───command.ps1      # Command parsing and execution
│   ├───pipeline.ps1     # Pipeline execution logic
│   ├───result.ps1       # Result type implementation
│   └───log.ps1          # Logging system
│
└───all/                 # Command implementations
    │   all.ps1
    └───my/
        │   my.ps1
        └───homies/
            │   homies.ps1
            └───hate/
                │   hate.ps1
                └───windows/
                        windows.ps1
```

## Development and Extension

To add a new command:

1. If it fits within an existing namespace, add a new `.ps1` file in the appropriate directory
2. If you need a new namespace, create a new folder and corresponding `.ps1` file
3. Ensure your command uses the Result pattern for error handling
4. Use the logging system for debugging and monitoring

## Extending with your commands
*TODO*
The user should be able to call `all -Create` and it should prompt them for the command details like the name and the location of the ps1 file to be copied into the `all` namespace. Similarly, all the other namespaces should have the same functionality. This should be able to be done non-interactively with parameters. Ex: `all my homies -Create "my new command" "C:\path\to\new\command.ps1"` or even `all my homies -Create "say hello" "echo 'Hello, world!'"` and a new command should be created for `all my homies say hello` that will execute the command `echo 'Hello, world!'`.
*TODO*

## Error Handling

All functions use the Result pattern with `Ok` and `Err` return types:

```powershell
function MyFunction {
    # Success case
    return Ok "Operation succeeded"
    
    # Error case
    return Err "Something went wrong"
    
    # Optional error (won't halt execution)
    return Err -Msg "Non-critical error" -Optional $true
}
```

## Logging

The library includes a built-in logging system:

```powershell
# Log an informational message
Log-Info "Operation started"

# Log a warning
Log-Warning "Potential issue detected"

# Log an error
Log-Error "Operation failed"
```

## License

MIT License - See LICENSE file for details